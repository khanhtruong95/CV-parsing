# Documentation Index — DentaMatch Candidate Onboarding

Welcome to the documentation suite for the Rails 8.1 candidate onboarding application. Start here to navigate to relevant guides.

## Core Documentation

| Document | Purpose | Audience |
|----------|---------|----------|
| **[codebase-summary.md](./codebase-summary.md)** | Directory map, 14 models, relationships, request flows, services, jobs, Stimulus controllers, test layout | Developers (new to codebase) |
| **[code-standards.md](./code-standards.md)** | Conventions, naming, validation patterns, testing strategy, database schema practices | All developers |
| **[system-architecture.md](./system-architecture.md)** | Component diagram, two databases (primary + queue), CV parsing pipeline, security model, ENV config, timeouts | Architects, DevOps, Backend leads |
| **[deployment-guide.md](./deployment-guide.md)** | Local setup, test commands, production deployment, scaling, monitoring, rollback | DevOps, Backend leads |
| **[project-overview-pdr.md](./project-overview-pdr.md)** | PRD & acceptance criteria (client requirements) | Product managers, QA |
| **[tech-stack.md](./tech-stack.md)** | Framework choices, rationale, key gems | Technical leads |

## Quick Navigation

**I want to...**
- **Understand the app** → Start with [codebase-summary.md](./codebase-summary.md)
- **Write code** → Read [code-standards.md](./code-standards.md)
- **Deploy to production** → Follow [deployment-guide.md](./deployment-guide.md)
- **Debug parsing** → See [system-architecture.md](./system-architecture.md) (Parsing Pipeline section)
- **Check requirements** → See [project-overview-pdr.md](./project-overview-pdr.md)

## Key Concepts at a Glance

**Models:** 14 core entities (CandidateProfile, CandidateDocument, User, Education, WorkExperience, 8 join/lookup tables)

**Request flow:** Upload CV → Parse (Claude API) → Prefill form → Candidate reviews → Admin notified

**Services:** CV extraction (format adapters) → CV parsing (Claude client) → Prefill (field matchers) → Completion (user linking + notifications)

**Jobs:** ParseCandidateCvJob (retry/discard logic), CandidateWebhookJob (fire-and-forget)

**Tests:** 139 tests across models, controllers, services, jobs, system flows

**Databases:** Primary (app data) + Queue (Solid Queue)

**Security:** HTTP Basic auth (admin), session-based (candidate), Active Storage private by default, rate limits, data minimization

---

Last updated: 2026-07-11. Docs track the completed Rails 8.1 app and should be updated when:
- New models or services are added
- Request flows change
- Deployment topology evolves
- Security practices shift
