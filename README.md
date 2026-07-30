# DentaMatch

Candidate onboarding for a dental recruitment platform. A candidate uploads their CV, we extract their details with the Claude API, and they review and complete a prefilled profile before submitting. Recruiters see completed profiles in a small admin area.

## Requirements

- Ruby 4.0.2 (see `.ruby-version`)
- PostgreSQL 14+
- An Anthropic API key (without one, development parses CVs with built-in sample data; production falls back to manual entry)

## Setup

```bash
bundle install
cp .env.example .env    # add ANTHROPIC_API_KEY and an ADMIN_PASSWORD
bin/rails db:prepare    # creates the app and queue databases
bin/rails db:seed       # job functions, skills, regions, languages
bin/rails server
```

Open http://localhost:3000. Background jobs (CV parsing) run inside Puma in development, so no extra process is needed.

Handy in development:

- **Try a sample CV** on the upload screen runs the whole flow with built-in sample data — no API key or real CV needed (hidden in production).
- The admin area is at `/admin`, behind HTTP basic auth using `ADMIN_USERNAME` / `ADMIN_PASSWORD` from your `.env`.
- Admin notification emails collect at `/letter_opener` instead of being delivered.

## Environment variables

| Variable | Purpose |
|---|---|
| `ANTHROPIC_API_KEY` | Claude API key for CV parsing |
| `ADMIN_USERNAME` / `ADMIN_PASSWORD` | Admin login (password is required in production) |
| `ADMIN_EMAIL` | Recipient for new-profile notifications |
| `CV_MAX_SIZE_MB` | Upload size limit, default 25 |
| `WEBHOOK_URL` | Optional; receives a POST when a candidate completes onboarding |

## Tests

```bash
bin/rails test          # unit + integration
bin/rails test:system   # browser tests (headless Chrome)
bin/rubocop
```

## More

Architecture, data model, and deployment notes live in [docs/](docs/README.md).
