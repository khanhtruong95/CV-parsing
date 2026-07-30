# DentaMatch Project Roadmap

## Completed Phases

### Phase "MVP — Candidate Onboarding with CV Upload" — COMPLETE (2026-07-11)

**7-phase implementation** delivering a zero-login candidate onboarding flow with AI-powered CV analysis.

**Delivery Summary:**
- Two-step flow: CV upload → Claude parsing → prefilled 8-section review form
- Intelligent CV extraction via Claude Sonnet with confidence scoring + manual review badges
- Prefilled profile form with 8 sections (personal, job preferences, employment, education, work history, skills, availability, notes)
- Conditional field logic: salary/percentage/BIG registry/daily revenue fields show/hide per job function + employment type
- Repeater fields for education, work experience, and language proficiency
- Skills filtered by job function with server-side matching to skill taxonomy
- Private storage for CVs (no public URLs, authenticated admin download only)
- Admin dashboard (HTTP Basic): list completed profiles, view details, download CVs, flag duplicate emails
- Email notifications to admin + optional webhook for external systems (fire-and-forget)
- 30-day purge task for stale draft profiles + attachments
- **139 passing tests** covering models, parsing job, prefill service, controllers, integrations, system journeys, and admin workflows

**Quality Assurance:**
- Security review: 20 findings addressed pre-launch (parsing race conditions, enum handling, admin template escaping, transaction isolation, etc.)
- Post-implementation code review: 8/10 initial score, 8 findings fixed (parse-race guard, enum validation, admin XSS prevention, join-id locking, purge scheduling, mailer config, array normalization, threshold alignment)
- System test coverage: 3 core user journeys (happy path with repeaters, parse failure fallback, conditional logic)
- 2 UI bugs discovered + fixed during system testing (employment-chip action, blank array handling)
- Security checks: brakeman clean, rubocop (omakase) clean

---

## Planned Phases

### Phase 2: Production Deployment & Infrastructure
- S3 storage for production CVs (local disk in MVP only)
- SMTP mailer (letter_opener in dev, real SMTP in prod)
- APP_HOST configuration for webhook callbacks
- Database backups and monitoring setup

### Phase 3: Email Verification & Candidate Accounts
- Email verification flow (OTP or confirmation link)
- Optional candidate login to view/edit submitted profile
- Session-based or token-based authentication

### Phase 4: Admin Account Merge UI
- Manual merge interface for duplicate-email flagged profiles (MVP just flags, no merge)
- Conflict resolution workflow for duplicate data

### Phase 5: BIG Registry Validation
- Real-time validation against Dutch BIG (Beroepsregister Individuele Gezondheidszorg) API
- Automatic status verification for dental professionals

### Phase 6: Matching Engine
- Candidate ↔ job vacancy matching algorithm
- Scoring based on location, skills, experience, employment type
- Recommendation feed for candidates and recruiters

### Phase 7: Multilingual UI
- Dutch + English interface localization
- Translated CV parsing + field prompts
- Localized validation messages and help text

### Phase 8: Distributed Cache for Rate Limiting
- Redis or Memcached for multi-node Rack::Attack throttle state
- Replaces current in-memory throttling (suitable for single-server MVP only)

---

**Status:** MVP complete and ready for pilot deployment.  
**Next Action:** Provision S3 + SMTP + staging environment for production readiness testing.
