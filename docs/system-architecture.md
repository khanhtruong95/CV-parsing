# System Architecture — DentaMatch Candidate Onboarding

**Target environment:** Rails 8.1 on Ruby 4.0 with PostgreSQL 18, Puma (dev), and Solid Queue (development runs jobs in-process).

## High-Level Component Diagram

```
                          ┌─────────────────────────────────┐
                          │   Candidate Browser             │
                          │  (HTML/CSS/JS via Importmap)   │
                          └────────────┬────────────────────┘
                                       │ HTTP
                          ┌────────────▼────────────────────┐
                          │ Rails 8.1 + Hotwire Stack      │
                          │ ┌──────────────────────────────┐│
                          │ │ Onboarding Controllers       ││
                          │ │ (cv_uploads, profiles,       ││
                          │ │  completions)                ││
                          │ └────────┬───────┬──────┬───────┘│
                          │          │       │      │        │
        Stimulus ◄────────┼──────────┤       │      │        │
        Controllers (5)   │          │       │      │        │
                          │ ┌────────▼───────▼──────▼────────┐│
                          │ │ Services & Models              ││
                          │ │ ┌──────┐ ┌────────┐┌──────────┐││
                          │ │ │CV    │ │Prefill ││Completion││
                          │ │ │Extra ││Service ││Service    ││
                          │ │ │ction │ └────────┘└──────────┘│
                          │ └──────────────────────────────────┤
                          │                                    │
                          └────────────┬────────────────────────┘
                                       │
                  ┌────────────────────┼────────────────────┐
                  │                    │                    │
                  ▼                    ▼                    ▼
        ┌──────────────────┐ ┌──────────────────┐ ┌──────────────────┐
        │ PostgreSQL       │ │ PostgreSQL       │ │ Claude API       │
        │ Primary DB       │ │ Queue DB         │ │ (Anthropic)      │
        │                  │ │ (Solid Queue)    │ │ cv_parsing/      │
        │ ┌─────────────────┤ │                  │ │ claude_client    │
        │ │Profiles         │ │ ┌──────────────┐ │ │                  │
        │ │Documents        │ │ │Job Queue     │ │ └──────────────────┘
        │ │Educations       │ │ │Timers        │ │
        │ │Experience       │ │ └──────────────┘ │  Optional:
        │ │Languages        │ │                  │  ┌──────────────────┐
        │ │Skills           │ └──────────────────┘  │ Webhook Endpoint │
        │ │+ lookup tables  │                       │ (external)       │
        │ └─────────────────┤                       └──────────────────┘
        │                   │
        └───────────────────┘

        ▲ Admin endpoint
        │ (HTTP Basic auth)
        └──── /admin/candidate_profiles
```

## Database Architecture

### Primary Database (`dentamatch_development`)
**Purpose:** All application data and business logic.

**Isolation:** App (Rails) reads/writes here only. No Solid Queue traffic.

**Tables:**
- **candidate_profiles** — Main entity: personal info, job prefs, employment, BIG status, timestamps, field_provenance (JSONB)
- **candidate_documents** — CV uploads with parsing status + raw parsed output (transient)
- **educations, work_experiences** — Nested repeaters
- **candidate_skills, candidate_languages, candidate_regions, candidate_employment_types** — Join tables with through associations
- **skills, languages, regions, employment_types, job_functions** — Lookup tables (seeded, admin-managed)
- **users** — Account linking (created at profile completion if email unique)
- **active_storage_blobs, active_storage_attachments** — CV file metadata + attachment tracking

**Indexes:** Foreign keys, unique constraints (email, job_function key, language code), status fields, parsing_status.

### Queue Database (`dentamatch_development_queue`)
**Purpose:** Solid Queue job store (separate for isolation).

**Isolation:** Solid Queue writes here; app never reads from it directly.

**Tables:**
- **solid_queue_jobs** — Pending/retrying jobs with class, arguments, run_at
- **solid_queue_scheduled_executions** — Recurring job schedules
- **solid_queue_processes** — Worker process registry

**Migrations:** In `db/queue_migrate/` (separate migration path).

## Parsing Pipeline & Timeouts

**Critical thresholds:**

```
Candidate Upload
       ↓
   [Store → Job Enqueue]
       ↓
ParseCandidateCvJob starts
       ↓
┌──────────────────────────────────────────┐
│ CvExtraction::Extractor.call(document)   │
│ Timeout: 20s (zip-bomb / pathological)   │
│                                          │
│ Dispatches to adapter:                   │
│ • PdfAdapter (via Anthropic gem)        │
│ • DocxAdapter (docx gem)                │
│ • DocAdapter (textutil/LibreOffice)     │
└──────────────────────────────────────────┘
       ↓ (extracted text or PDF bytes)
┌──────────────────────────────────────────┐
│ CvParsing::ClaudeClient.new.extract()   │
│ Timeout: 120s                           │
│ (well under stuck-processing guard)     │
│                                          │
│ POST to Claude API                      │
│ • Tool-use schema with {value,conf}    │
│ • Max 4096 tokens response              │
└──────────────────────────────────────────┘
       ↓ (structured JSON or error)
       
   IF RetryableApiError (5xx, rate-limit)
       ↓ retry exponential backoff (3 attempts)
   
   IF NonRetryableApiError (4xx, auth)
       ↓ discard immediately (log + mark failed)
   
   IF EmptyContent (all nulls)
       ↓ discard (CV has no extractable data)
       
   IF success
       ↓
   ┌───────────────────────────────────────┐
   │ PrefillService.new(profile, result)   │
   │ .call                                 │
   │                                       │
   │ Check prefilled_at (idempotency)      │
   │ Map results → profile + child records │
   │ Record field_provenance per field     │
   │ Clear parsed_data (privacy)           │
   │ Save profile + educations/experience  │
   └───────────────────────────────────────┘
       ↓ success
   CandidateDocument.update(
     parsing_status: :completed,
     parsed_at: now,
     parsed_data: {}  # cleared
   )
```

### Stuck-Processing Guard
**Threshold:** 3 minutes (`STUCK_PROCESSING_AFTER`)

**Trigger:** Polling endpoint (`GET onboarding/cv/status`) every 2s. If doc in `processing` state + `updated_at` > 3min ago → flips to `failed`.

**Rationale:**
- Claude client timeout is 120s, so 3min gives buffer for job queue delays
- Client poll give-up is ~200s, so guard triggers within poll window
- Prevents candidate polling forever if job worker crashed mid-parse

## Security Model

### Authentication
- **Candidate:** Session-based (`session[:candidate_profile_id]`). No login required; session created at first CV upload.
- **Admin:** HTTP Basic auth middleware in `app/controllers/admin/base_controller.rb`. Username/password from ENV.

### Authorization
- Candidate can only access their own profile (enforce via session).
- Admin endpoints require HTTP Basic auth (all-or-nothing access to all profiles).

### Active Storage
- **Default:** Private. CVs not publicly accessible.
- **Signed URLs:** Used for admin download (single-use, time-limited).
- **Service:** Local disk in dev; S3-compatible in production (configurable via `config/storage.yml`).

### Data Protection
- **Consent:** Required before upload; timestamp stored in `consent_accepted_at` for audit.
- **Parsed data:** Cleared after prefill (never persisted long-term).
- **Email deduplication:** No merge; flagged `duplicate_email` for manual admin review.
- **Purge:** 30-day auto-purge of abandoned drafts (Solid Queue recurring job).

### Input Validation & Sanitization
- **Email:** Regex validation (URI::MailTo::EMAIL_REGEXP)
- **Phone:** phonelib gem (Dutch-first, international fallback); normalized to E.164
- **CV type:** Validated on magic bytes (not client Content-Type)
- **File size:** Checked before blob creation; configurable `CV_MAX_SIZE_MB` (default 25)
- **Template injection:** ERB auto-escaped; no raw() on user data
- **Race conditions:** with_lock on completion (prevents double-save/notify)

### Rate Limiting
**Rack::Attack middleware:**
- CV upload: 10/hour per IP + 10/hour per session (throttle session via cookie hash)
- Onboarding writes (POST/PATCH): 60/hour per IP
- Throttle responder: 429 Too Many Requests

**Cache store:** Rails.cache (in-memory on single node). For multi-node production, configure shared cache (Solid Cache or Redis).

### Admin Credentials Validation
- **Production only:** Boot fails if ADMIN_PASSWORD missing, empty, or placeholder value (<12 chars)
- **Development:** No password check (convenience)

## ENV Configuration

| Variable | Purpose | Default | Required |
|----------|---------|---------|----------|
| **ANTHROPIC_API_KEY** | Claude API authentication | None | Yes (if parsing) |
| **CLAUDE_MODEL** | Model identifier | `claude-sonnet-5` | No |
| **CV_MAX_SIZE_MB** | Upload size limit (megabytes) | `25` | No |
| **ADMIN_USERNAME** | HTTP Basic auth username | `admin` | No (dev) |
| **ADMIN_PASSWORD** | HTTP Basic auth password | None | **Yes (production)** |
| **ADMIN_EMAIL** | Email recipient for notifications | None | No (uses default) |
| **WEBHOOK_URL** | External webhook endpoint (optional) | None | No |
| **APP_HOST** | Hostname for email links | `localhost:3000` | No (dev) |
| **MAILER_FROM** | Email sender address | `noreply@dentamatch.local` | No |
| **DATABASE_URL** | Primary DB connection string | `postgres://...` | No (uses database.yml) |
| **DENTAMATCH_DATABASE_PASSWORD** | DB password (production) | None | **Yes (production)** |
| **RAILS_MAX_THREADS** | DB connection pool size | `5` | No |
| **RAILS_ENV** | Rails environment | `development` | No |
| **RACK_ENV** | Rack environment | (inherits RAILS_ENV) | No |

### Loading Strategy
- **Development/Test:** `.env` file via dotenv-rails gem
- **Production:** Rails credentials or environment variables (no .env file)
- **Safety:** Never commit `.env`; `.env.example` documents all vars

## Performance Characteristics

**Parsing latency:** 5–30 seconds (Claude API round-trip, file extraction, prefill)

**Concurrent uploads:** Soft limit via Rack::Attack (10/hour per IP). Hard limit via Solid Queue worker pool.

**Polling:** Every 2s for ~30s max (total parse time). Client-side timeout ~200s triggers stuck guard.

**Database:**
- **Primary:** ~14 tables, small data volume (candidate profiles + CV metadata)
- **Queue:** Auto-cleanup after job completion (Solid Queue housekeeping)

## Deployment Topology

### Single-Node Production (Current)
- **Puma:** Rails + 2 worker processes (configurable)
- **Solid Queue:** Jobs run in-process within Puma (no separate worker pool needed)
- **PostgreSQL:** Two databases on same server (primary + queue)
- **Active Storage:** S3 or compatible object store (not local disk)
- **Rate limiting:** Relies on single-node Rails.cache (no shared cache needed)

### Multi-Node Production (Future)
**Changes needed:**
- **Solid Queue:** Deploy separate job worker processes (or keep in-process on each Puma instance)
- **Cache store:** Switch to Solid Cache or Redis (for Rack::Attack throttle counters)
- **Session store:** Use Rails.cache (if shared) or encrypted cookies (Rails 8 default)
- **Database replication:** Read replicas optional (currently all writes to primary)

## Observability & Logging

- **Parse failures:** Logged with reason (timeout, invalid API key, empty CV)
- **Webhook failures:** Logged as warnings (fire-and-forget, no retry)
- **Rate limit hits:** Logged by Rack::Attack
- **Database migration issues:** Standard Rails migrations log
- **Job status:** Tracked in `parsing_status` enum on CandidateDocument

**No APM/metrics integration yet** (out of scope for MVP).
