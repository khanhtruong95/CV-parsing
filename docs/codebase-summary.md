# Codebase Summary — DentaMatch Candidate Onboarding

**Overview:** Rails 8.1 app for two-step CV-driven candidate onboarding. Core flow: upload CV → Claude parses → form prefill → candidate reviews/edits → admin reviews. ~400 lines code (models, services, controllers), ~700 lines tests (139 tests).

## Directory Structure

```
app/
├── models/                      # 14 models (see Models section below)
├── controllers/
│   ├── onboarding/             # Two-step flow (cv_uploads, profiles, completions)
│   └── admin/                  # Read-only candidate profile dashboard
├── services/
│   ├── cv_extraction/          # File-type adapters (PDF, DOCX, DOC)
│   ├── cv_parsing/             # Claude API client + schema
│   ├── prefill/                # Field matchers (job function, skill, language, phone, date)
│   └── completion/             # Save profile + user linking + notifications
├── jobs/                       # ParseCandidateCvJob, CandidateWebhookJob
├── javascript/controllers/     # 5 Stimulus controllers (see Stimulus section)
├── helpers/                    # ProvenanceBadgeHelper (badge logic)
└── mailers/                    # AdminMailer

config/
├── database.yml               # Two Postgres DBs (primary, queue)
├── routes.rb                  # 2 namespaces (onboarding, admin)
├── recurring.yml              # 30-day purge schedule (production)
└── initializers/
    ├── app_config.rb          # CV_MAX_SIZE_MB, CLAUDE_MODEL from ENV
    ├── rack_attack.rb         # Rate limits for CV upload/writes
    └── admin_credentials_check.rb  # Production password validation

db/
├── schema.rb                  # 14 core tables + Active Storage
├── queue_schema.rb            # Solid Queue infrastructure
└── seeds.rb                   # Idempotent seeding (find_or_create_by)

test/
├── controllers/               # 4 controller tests (CV, profile, complete, admin)
├── models/                    # 4 model tests
├── services/                  # 8 service/matcher tests
├── jobs/                      # 1 job test
└── system/                    # 3 system tests (end-to-end flows)
```

## 14 Models & Relationships

| Model | Purpose | Key Attributes |
|-------|---------|-----------------|
| **CandidateProfile** | Main profile (one per onboarding session). Stores personal, job preferences, employment, BIG, timestamps. | `first_name`, `last_name`, `email`, `phone`, `city`, `country`, `job_function_id`, `big_status`, `big_number`, `years_experience`, `search_status`, `completed_at`, `field_provenance` (JSONB tracking CV extraction confidence per field), `prefilled_at` (used by PrefillService to prevent re-running) |
| **User** | Account linking (created at profile save iff email is unique). | `email` (unique), `first_name`, `last_name` |
| **CandidateDocument** | Uploaded CV + parsing state. Parsing status tracked here; raw AI output (`parsed_data` JSONB) stored transiently during job, then cleared for privacy. | `document_type`, `parsing_status` (enum: pending/processing/completed/failed), `parsed_data`, `parsed_at`, `failure_reason` |
| **Education** | Nested repeater under profile. No FK to preset table; free-text `study` and `institution`. Level is enum-ish (MBO/HBO/Bachelor/Master/Doctor/Course). Position orders rows. | `study`, `institution`, `location`, `level`, `start_date`, `end_date`, `position` |
| **WorkExperience** | Nested repeater under profile. | `job_title`, `company_name`, `responsibilities`, `start_date`, `end_date`, `current_job` (boolean), `position` |
| **CandidateLanguage** | Join: profile ↔ language + level (A1–C2, fluent, native). Respects `marked_for_destruction?` in validation. | `language_id`, `level`, `candidate_profile_id` |
| **Language** | Preset list (e.g., Dutch, English, French). Seeded. | `name`, `code` (ISO 639), `position` |
| **CandidateRegion** | Join: profile ↔ region. Multi-select. | `region_id`, `candidate_profile_id` |
| **Region** | Preset Dutch regions (e.g., North Holland, South Holland). | `name`, `code`, `position` |
| **CandidateSkill** | Join: profile ↔ skill (scoped to job function). PrefillService auto-matches extracted skill names; unmatched stored in `suggested_skills` text field. | `skill_id`, `candidate_profile_id` |
| **Skill** | Preset list per job function (e.g., "endodontics" under Dentist). | `name`, `job_function_id`, `position` |
| **CandidateEmploymentType** | Join: profile ↔ employment type. Multi-select. Validates that ≥1 type selected. | `employment_type_id`, `candidate_profile_id` |
| **EmploymentType** | Preset list (e.g., employed, self-employed, freelance, percentage-based). Flags `salary_based`, `percentage_based` control conditional form fields. | `name`, `key`, `salary_based`, `percentage_based`, `position` |
| **JobFunction** | Preset list (e.g., General Dentist, Hygienist, Assistant). Flags `requires_big`, `requires_daily_revenue` control conditional validations. | `name`, `key`, `requires_big`, `requires_daily_revenue`, `position` |

**Key relationships:**
- CandidateProfile has_many [:candidate_documents, :educations, :work_experiences, :candidate_skills, :candidate_languages, :candidate_regions, :candidate_employment_types]
- Through associations: skills, languages, regions, employment_types
- All dependent: :destroy to cascade on profile deletion

## Request Flows

### Flow 1: CV Upload → Parsing → Prefill
1. **GET onboarding/cv** — Candidate lands on upload form. Controller checks latest doc status (pending/processing/completed/failed) and renders corresponding state.
2. **POST onboarding/cv** — Candidate uploads file + consent checkbox. Controller:
   - Validates consent, file presence
   - Creates CandidateProfile (if new session) + CandidateDocument + attaches file
   - Saves to session: `session[:candidate_profile_id]`
   - Enqueues `ParseCandidateCvJob`
   - Redirects to CV upload path (still shows processing state)
3. **GET onboarding/cv/status** (polled every 2s via Turbo) — Shows parse progress. If doc stuck >3min, flips to failed.
4. **POST onboarding/cv/skip** — Candidate skips parsing, goes straight to manual form.
5. **ParseCandidateCvJob** (background, Solid Queue):
   - CvExtraction::Extractor dispatches file to adapter (PDF/DOCX/DOC)
   - CvParsing::ClaudeClient sends extracted text + schema to Claude API (timeout: 120s)
   - PrefillService maps result to profile, records `field_provenance` per field (confidence: high/medium/low)
   - Clears `parsed_data` for privacy
   - Catches retryable errors (5xx, rate-limit) → 3 retries. Non-retryable (4xx, missing key) → fail immediately.

### Flow 2: Profile Review & Completion
1. **GET onboarding/profile** — Prefilled form with badges ("Extracted from CV" / "Please check" / "Missing") driven by `field_provenance` + required-field logic.
2. **PATCH onboarding/profile** — Candidate edits fields. Stimulus controllers (conditional_fields_controller, skills_filter_controller) show/hide fields based on job_function. Nested-form-controller handles add/remove education/work rows.
3. **GET onboarding/complete** — Final review screen showing summary.
4. **Completion::SaveProfile** service (stateless, called by completions_controller):
   - Validates profile under `:complete` context (required fields only)
   - Saves profile inside transaction with join-table assignments
   - Uses `with_lock` to ensure exactly one completion (idempotent on retry/double-submit)
   - Links User (creates new if email unique, flags `duplicate_email` if exists)
   - Runs notifications: AdminMailer + optional CandidateWebhookJob

### Admin Flow
- **GET /admin** — Dashboard listing completed profiles with email, name, status.
- **GET /admin/candidate_profiles/:id** — Read-only profile detail.
- **GET /admin/candidate_profiles/:id/cv** — Download latest CV (Active Storage private by default, then HTTP Basic auth gates it).

## Services

### CvExtraction
- **Extractor** — Dispatches on `blob.content_type` (magic bytes, not client header) to adapter. 20s timeout per file.
- **PdfAdapter** — Uses Anthropic Ruby gem's direct PDF input (base64) for <100 pages.
- **DocxAdapter** — `docx` gem text extraction → pass as text to Claude.
- **DocAdapter** — Shell out to `textutil` (macOS) or LibreOffice (Linux); graceful fallback.

### CvParsing
- **ClaudeClient** — Single integration point. Sends extracted content (PDF bytes or text) + structured schema to Claude API. Timeouts: 120s. Raises `RetryableApiError` (5xx, rate-limit) or `NonRetryableApiError` (4xx, auth, size).
- **ExtractionSchema** — Defined in code; specifies tool schema with every field as `{value, confidence}`. System prompt: "extract only what is present, never invent."

### Prefill
- **PrefillService** — Maps Claude result to profile + child records. Records per-field provenance. Idempotent: skips if `prefilled_at` already set.
- **JobFunctionMatcher** — Fuzzy-matches extracted job function name + current job title to preset list.
- **SkillMatcher** — Extracts skill names, matches against preset list for selected job function; stores unmatched as free-text suggestions.
- **LanguageMatcher** — Matches language name, normalizes level.
- **PhoneNormalizer** — Parses + formats phone (Dutch-first via phonelib gem).
- **DateParser** — Flexible date parsing (handles partial dates, ranges, "current").

### Completion
- **SaveProfile** — Validates profile (`:complete` context), persists, links/creates User, sends notifications. Implements race-guard via `with_lock`. Returns Result struct (success boolean + profile).

## Jobs

### ParseCandidateCvJob (ActiveJob, Solid Queue)
- **Queue:** default
- **Retries:** 3 exponential backoff on `RetryableApiError` + `Timeout::Error`
- **Discard:** `CvExtraction::Unsupported`, `CvParsing::EmptyContent`, `CvParsing::NonRetryableApiError`
- **Idempotency:** Checks `document.completed? || failed?` and bails (already transitioned or failed concurrently). After prefill, reloads doc; if another worker failed it, bails without prefilling.
- **Race guards:** Stuck-processing flip (3min, candidate-side polling trigger); concurrent save handling in Completion::SaveProfile (with_lock).

### CandidateWebhookJob (ActiveJob, Solid Queue, fire-and-forget)
- **Trigger:** Completion::SaveProfile, only if WEBHOOK_URL set
- **Payload:** `{event, profile_id, full_name, email, job_function, completed_at}`
- **Retry:** None (discarded on any error, logged as warning)

## Stimulus Controllers (5 total)

| Controller | File | Purpose |
|------------|------|---------|
| **conditional_fields_controller** | `conditional_fields_controller.js` | Toggles visibility of salary/percentage/BIG/skills fields based on job_function + employment_types selections. Used on profile form. |
| **cv_poll_controller** | `cv_poll_controller.js` | Polls GET onboarding/cv/status every 2s during parsing. Shows progress, switches to failure/success view on transition. |
| **cv_upload_controller** | `cv_upload_controller.js` | Drag-and-drop + click file upload. Shows file name, enforces size limit client-side. |
| **nested_form_controller** | `nested_form_controller.js` | Adds/removes education & work-experience rows. Uses `<template>` element + hidden position field to track order. |
| **skills_filter_controller** | `skills_filter_controller.js` | Filters available skills by selected job_function. Unchecks skills not in filtered set. |

All files use kebab-case naming; Stimulus identifiers match filename without `.js`.

## Provenance & Badge System

**Stored on profile:** `field_provenance` (JSONB). Example:
```json
{
  "first_name": {"source": "cv", "confidence": "high"},
  "phone": {"source": "cv", "confidence": "medium"},
  "job_function_id": {"source": "cv", "confidence": "low"}
}
```

**Helper:** ProvenanceBadgeHelper determines field state:
- `:cv` — High confidence extraction (green badge)
- `:check` — Low/medium confidence (amber badge "Please check")
- `:missing` — Required field, no extraction + not filled (red badge)
- `:none` — No badge

**Badges** — Rendered in profile form sections via `badge` partial. Top banner shows counts (extracted/check/missing).

## Test Suite (139 tests across 21 files)

### Models (4 files, ~30 tests)
- **candidate_profile_test** — Draft vs. complete validation, required field logic, relation setup
- **candidate_document_test** — File validation (spoofing, type, size), stuck-processing detection
- **education_test, work_experience_test** — Nested model validations

### Controllers (4 files, ~50 tests)
- **onboarding/cv_uploads_controller_test** — Upload, status polling, skip, consent, error flows
- **onboarding/profiles_controller_test** — Form rendering, nested attributes, validation errors
- **onboarding/completions_controller_test** — Save profile, user linking, duplicate email handling
- **admin/candidate_profiles_controller_test** — Auth, listing, show, CV download

### Services (8 files, ~35 tests)
- **prefill_service_test** — Full prefill flow, provenance recording, field mapping
- **prefill/job_function_matcher_test, skill_matcher_test, language_matcher_test, phone_normalizer_test, date_parser_test** — Unit tests for matchers
- **completion/save_profile_test** — Validation, user linking, race conditions

### Jobs (1 file, ~8 tests)
- **parse_candidate_cv_job_test** — Job dispatch, retry/discard conditions, stuck-guard side effects

### System (3 files, ~16 tests)
- **onboarding_manual_path_test** — Full onboarding without parsing (skip flow)
- **parse_failure_fallback_test** — Parse fails → candidate forced to manual path
- **conditional_fields_test** — Job function changes drive field visibility

### Test helpers
- **fixtures/** — Seeded test data (candidate_profiles, documents, job_functions, regions, languages, employment_types)
- **application_system_test_case** — Capybara + Selenium setup
- **webmock** — Stubs Claude API calls

## Key Implementation Patterns

1. **:complete validation context** — Only enforced at final save, not at draft creation (allows resume).
2. **Service-managed columns excluded from strong params** — `field_provenance`, `parsed_data`, `prefilled_at`, `completed_at` set by services, never mass-assigned.
3. **ERB auto-escaping** — No `raw()` or `html_safe` on user data; badges use safe HTML partials.
4. **Stimulus data attributes** — Controllers read `data-*` for thresholds, IDs, URLs (e.g., `data-cv-max-size`).
5. **Transactional integrity** — ParseCandidateCvJob inside transaction; Completion::SaveProfile with_lock for atomicity.
6. **Idempotent operations** — PrefillService checks `prefilled_at`; Completion checks `profile_completed?` before re-notifying.
