# Deployment Guide — DentaMatch Candidate Onboarding

**Scope:** Local development setup, test execution, and production deployment considerations.

## Local Development Setup

### System Prerequisites
- **macOS (Homebrew keg-only):**
  ```bash
  # Ruby (keg-only; must add to PATH)
  export PATH="/opt/homebrew/opt/ruby/bin:$PATH"
  ruby --version  # Should be 4.0.2 or later
  
  # PostgreSQL 18
  brew services start postgresql@18
  psql --version
  
  # Node.js (optional; app uses importmap, not Node build)
  ```
- **Linux/Other:** Install Ruby 4.0+, PostgreSQL 18, standard build tools

### Initial Setup (one-time)

```bash
# Clone repository
git clone <repo-url> dentamatch
cd dentamatch

# Install Ruby dependencies
bundle install

# Setup databases (dev + test + queue DBs)
bin/setup

# This runs:
# • bundle check
# • bin/rails db:prepare (create + migrate + seed primary DB)
# • bin/rails db:reset (if --reset flag)
# • bin/rails log:clear tmp:clear
# • bin/dev (starts dev server)
```

### Manual Database Setup (if needed)
```bash
# Create databases
bin/rails db:create

# Migrate primary DB
bin/rails db:migrate

# Migrate queue DB
bin/rails db:migrate:queue

# Seed lookup tables (idempotent)
bin/rails db:seed

# Create test databases
RAILS_ENV=test bin/rails db:create db:migrate db:migrate:queue
```

### Environment Configuration
```bash
# Copy template
cp .env.example .env

# Edit .env (required for parsing):
# ANTHROPIC_API_KEY=sk-ant-...
# ADMIN_USERNAME=admin
# ADMIN_PASSWORD=dev-password-only

# dotenv-rails loads .env automatically in development
```

### Development Server

**Option 1: Procfile-based (recommended)**
```bash
bin/dev
# Starts Puma + Solid Queue jobs + Tailwind watcher
# Rails at http://localhost:3000
# Admin at http://localhost:3000/admin (user: admin, pass: from .env)
```

**Option 2: Rails server only**
```bash
bin/rails server
# Puma at http://localhost:3000
# Jobs will queue but won't process (no worker running)
```

**Option 3: Solid Queue job console**
```bash
# In separate terminal, while bin/dev is running:
bin/rails console
SolidQueue::Job.count  # Check pending jobs
```

### First Onboarding Test

1. Navigate to http://localhost:3000/
2. Click "Start Onboarding"
3. Upload a PDF/DOCX CV (or skip)
4. If parsing: wait 5–30s (polls every 2s)
5. Fill profile form, save
6. Check admin dashboard: http://localhost:3000/admin

## Testing

### Prerequisites
- Test databases auto-created by `bin/rails db:prepare`
- webmock gem stubs Claude API (no real API calls in tests)
- Capybara + Selenium for system tests

### Unit & Integration Tests
```bash
# Run all tests
bin/rails test

# Run specific test file
bin/rails test test/models/candidate_profile_test.rb

# Run specific test
bin/rails test test/models/candidate_profile_test.rb --name test_draft_profile

# Verbose output
bin/rails test --verbose

# Coverage (requires simplecov gem; not included by default)
```

### System Tests (Browser)
```bash
# All system tests
bin/rails test:system

# Specific system test
bin/rails test:system test/system/onboarding_manual_path_test.rb

# Browser stays open for inspection (set in application_system_test_case.rb)
```

### Test Database Reset
```bash
# If tests fail due to stale data:
RAILS_ENV=test bin/rails db:migrate:reset

# Or via Rake:
bin/rails test:prepare
```

### Test Structure (Quick Reference)
- **Models:** `test/models/*_test.rb` — Validation, enum, relation tests
- **Controllers:** `test/controllers/**/*_test.rb` — Request/response, redirects, error handling
- **Services:** `test/services/**/*_test.rb` — Business logic, transaction safety
- **Jobs:** `test/jobs/*_test.rb` — Retry conditions, error handling
- **System:** `test/system/*_test.rb` — Full onboarding flows with browser

### Code Quality & Security Scanning
```bash
# Linting (Omakase)
bin/rails rubocop

# Security: Brakeman (static analysis)
bundle exec brakeman

# Gem audit
bundle audit check --update

# All three:
bin/rails quality_checks  # If Rake task defined; otherwise run individually
```

## Production Deployment

### Pre-Deployment Checklist

**Environment variables (required):**
- ✓ ANTHROPIC_API_KEY (for CV parsing)
- ✓ ADMIN_PASSWORD (12+ chars, strong)
- ✓ ADMIN_USERNAME (default: admin)
- ✓ ADMIN_EMAIL (notification recipient)
- ✓ DENTAMATCH_DATABASE_PASSWORD (DB user password)
- ✓ APP_HOST (e.g., dentamatch.example.com)
- ✓ MAILER_FROM (e.g., noreply@dentamatch.example.com)

**Optional:**
- WEBHOOK_URL (external webhook on completion)
- CV_MAX_SIZE_MB (default: 25)
- CLAUDE_MODEL (default: claude-sonnet-5)

**Rails configuration (config/environments/production.rb):**
- ✓ `config.force_ssl = true` (HTTPS only)
- ✓ Correct database host/port
- ✓ Action Mailer SMTP configured (not letter_opener)
- ✓ Active Storage service configured (S3, GCS, etc.)

### Database Preparation
```bash
# On production server (one-time)
RAILS_ENV=production bin/rails db:create
RAILS_ENV=production bin/rails db:migrate
RAILS_ENV=production bin/rails db:migrate:queue
RAILS_ENV=production bin/rails db:seed

# Verify two DBs created:
psql -U dentamatch -l | grep dentamatch
# Should show: dentamatch_production, dentamatch_production_queue
```

### Deployment Steps
```bash
# 1. Pull/deploy code
git pull origin main
cd /var/www/dentamatch

# 2. Install gems (bundle will fail if Gemfile.lock stale)
bundle install --deployment

# 3. Assets (Propshaft auto-compiles; no extra rake task needed)

# 4. Migrations (zero-downtime if code is backward-compatible)
RAILS_ENV=production bin/rails db:migrate

# 5. Restart Puma
sudo systemctl restart dentamatch  # or equivalent for your deploy tool

# 6. Verify health
curl http://localhost:3000/up
```

### Production Services

**Puma web server:**
```bash
# systemd unit example (dentamatch.service):
[Unit]
After=network.target postgresql.service

[Service]
ExecStart=/usr/local/bin/bundle exec puma -t 5:10 -w 2 -b tcp://0.0.0.0:3000
WorkingDirectory=/var/www/dentamatch
Environment=RAILS_ENV=production
Restart=always

[Install]
WantedBy=multi-user.target
```

**Solid Queue job worker (in-process):**
- Runs within Puma via `config/puma.rb` hook
- No separate process needed (unless scaling horizontally)
- Jobs queue in `dentamatch_production_queue` DB

**Recurring jobs (config/recurring.yml):**
```yaml
production:
  purge_stale_candidate_profiles:
    command: "CandidateProfile.purge_stale!"
    schedule: "every day at 4am"
```
- Solid Queue supervisor runs recurring tasks on any worker
- 30-day purge cleans abandoned draft profiles + CV blobs

**Mailer:**
- Configure SMTP (not letter_opener in production)
- Set MAILER_FROM ENV
- Send test email: `AdminMailer.candidate_completed(profile).deliver_now`

**File storage (Active Storage):**
```ruby
# config/storage.yml
amazon:
  service: S3
  access_key_id: <%= ENV["AWS_ACCESS_KEY_ID"] %>
  secret_access_key: <%= ENV["AWS_SECRET_ACCESS_KEY"] %>
  bucket: dentamatch-cvs
  region: us-west-2

google:
  service: GCS
  credentials: <%= ENV["GOOGLE_CLOUD_CREDENTIALS"] %>
  project: dentamatch-prod
  bucket: dentamatch-cvs
```

**HTTPS:**
- Use reverse proxy (nginx) with Let's Encrypt cert
- Rails `config.force_ssl = true` redirects HTTP to HTTPS

### Monitoring & Maintenance

**Health check:**
```bash
# Rails built-in (zero DB dependencies)
curl https://dentamatch.example.com/up
```

**Logs (recommendations):**
- Stream to centralized logging (e.g., Datadog, LogRocket, papertrail)
- Monitor parse failures: grep "parsing_status.*failed" in logs
- Monitor webhook errors: "candidate_onboarding_completed webhook failed"

**Backups:**
- PostgreSQL: WAL-based backups (primary DB only; queue DB can be rebuilt)
- Active Storage: S3 versioning + lifecycle policies for deleted objects
- Database snapshots: Daily automated snapshots via cloud provider

**Database maintenance:**
- VACUUM + ANALYZE (PostgreSQL auto-maintenance via autovacuum)
- Monitor slow queries (log_min_duration_statement in postgresql.conf)
- Check index bloat periodically

### Scaling Considerations

**Horizontal scaling (if needed):**
1. **Database:** Use read replicas for reporting; writes still go to primary
2. **Solid Queue:** Deploy separate worker processes on dedicated machine(s)
3. **Cache store:** Switch to Solid Cache or Redis for shared rate-limit state (Rack::Attack)
4. **Session store:** Use encrypted cookies (Rails 8 default, already secure) or shared cache
5. **Active Storage:** S3/cloud storage already multi-node safe

**Rate limiting:** Current single-node setup uses Rails.cache (memory store). Multi-node deployments require shared cache:
```ruby
# config/environments/production.rb
config.cache_store = :solid_cache_store  # Shared DB-backed cache
# OR
config.cache_store = :redis_cache_store, { url: ENV["REDIS_URL"] }
```

### Rollback

If deployment breaks the app:
```bash
# 1. Rollback code
git revert <commit>
cd /var/www/dentamatch && bundle install

# 2. If migrations were added, rollback DB
RAILS_ENV=production bin/rails db:rollback STEP=1

# 3. Restart Puma
sudo systemctl restart dentamatch

# 4. Verify
curl https://dentamatch.example.com/up
```

### Production Admin Access

Admin dashboard at `/admin`. Credentials via HTTP Basic auth:
```bash
# Prompt will appear in browser
Username: (from ADMIN_USERNAME, default "admin")
Password: (from ADMIN_PASSWORD env var)

# Or via curl:
curl -u admin:password https://dentamatch.example.com/admin/candidate_profiles
```

### Known Limitations (Single-Node, MVP)

- **Solid Queue jobs:** Restart Puma to stop running jobs (no graceful shutdown hook yet)
- **Rate limiting:** Per-IP/session limits are in-memory; refresh rates across restarts
- **Polling:** No WebSocket support (simple 2s polling works for MVP scale)
- **File uploads:** No chunking for large files (configurable max 25 MB; adjust CV_MAX_SIZE_MB)

### Unresolved Production Questions

1. **Monitoring:** Which APM/observability tool? (Currently only logs)
2. **CI/CD:** How to deploy (GitHub Actions, Jenkins, manual)?
3. **SSL certificate:** Auto-renewal strategy (Let's Encrypt + certbot)?
4. **Incident response:** Who owns on-call alerts?
5. **GDPR/Privacy:** Data retention policy beyond 30-day purge?
