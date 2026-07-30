# Tech Stack — Candidate Onboarding Platform (Dental Recruitment)

Date: 2026-07-11 | Status: Selected

## Core

| Component | Choice | Rationale |
|-----------|--------|-----------|
| Framework | Ruby on Rails 8.1 | PRD preference; latest stable; Solid Queue/Cable built-in |
| Ruby | 4.0.2 (Homebrew, `/opt/homebrew/opt/ruby`) | Already installed on dev machine |
| Database | PostgreSQL 18 (Homebrew) | Multi-user writes, future ATS/matching (full-text, JSONB); already installed |
| Job queue | Solid Queue (ActiveJob) | DB-backed, no Redis; Rails 8 default |
| Frontend | Hotwire (Turbo + Stimulus), importmap, Propshaft | No Node build step; Rails default |
| CSS | Tailwind via `tailwindcss-rails` | Standalone binary, no bundler |
| File storage | Active Storage (local disk dev; S3-compatible later) | PRD requirement; private by default |

## CV Parsing

| Concern | Choice |
|---------|--------|
| Primary extraction | Claude API (`anthropic` official Ruby gem), model `claude-sonnet-5`, direct PDF input (≤100 pages/30MB) |
| DOCX | `docx` gem text extraction → text to Claude |
| Legacy .doc | Shell out to `textutil` (built into macOS) / LibreOffice headless in prod; graceful "continue manually" fallback |
| Schema | Structured JSON via tool-use schema; every field `{value, confidence}` with nullable values; "extract only what is present, never invent" system prompt |
| Pipeline | `ParseCandidateCvJob` (ActiveJob/Solid Queue), statuses: pending → processing → completed/failed, 3 retries exponential backoff |
| Raw output | Stored server-side on `CandidateDocument#parsed_data` (jsonb), never exposed to candidate |

## Key Gems

`rails ~> 8.1`, `pg`, `anthropic`, `docx`, `active_storage_validations`, `phonelib`, `tailwindcss-rails`, `solid_queue`, `image_processing` (AS default). Test: minitest (Rails default), `webmock` (stub Claude API).

## Form Patterns

- Two-step flow: plain routes (no wicked gem) — `onboarding/cv_upload` → `onboarding/profile`
- Parsing status: Turbo polling (refresh every 2s) — simpler than ActionCable broadcast for MVP
- Education/work-experience repeaters: `accepts_nested_attributes_for` + Stimulus nested-form controller (template element, hand-rolled ~40 LOC)
- Conditional fields (salary/percentage/BIG/skills by function): Stimulus toggle controller reading select values
- Multi-selects (languages, regions, transport, working days, skills): styled checkbox groups (KISS, no tom-select)

## Decisions & Trade-offs

1. **Postgres over SQLite**: extra local setup vs. required for future matching. Postgres 18 already installed → chosen.
2. **Claude direct-PDF over text-extraction-first**: preserves layout/tables; text fallback for DOCX/DOC and oversized PDFs.
3. **Polling over WebSocket** for parse status: 1 line of Turbo, no cable infra; parse takes 5–30s.
4. **No external parse SaaS** (Affinda ~$0.50/CV) vs Claude ~$0.01–0.03/CV: Claude primary; SaaS only if quality fails in pilot.
5. **Consent checkbox** stored as timestamp on profile (simple, auditable).

## Environment Notes (dev machine)

- Ruby: `export PATH="/opt/homebrew/opt/ruby/bin:$PATH"` (keg-only)
- Postgres: `brew services start postgresql@18`; binaries at `/opt/homebrew/opt/postgresql@18/bin`
- `ANTHROPIC_API_KEY` required in env for parsing (dotenv-rails or Rails credentials)

## Unresolved Questions

1. Production hosting target (affects storage service + deploy docs) — deferred.
2. BIG number live validation against registry — out of MVP scope per PRD.
3. Admin notification channel (email vs webhook) — MVP: email via ActionMailer log/letter_opener in dev + `candidate_onboarding_completed` webhook stub.
