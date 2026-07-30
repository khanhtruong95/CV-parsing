# Code Standards — DentaMatch Candidate Onboarding

**Objective:** Document the conventions actually used in the codebase to enable consistent future maintenance and extensions.

## File Organization & Naming

### Ruby Files
- **Models:** PascalCase class names (`CandidateProfile`, `CandidateDocument`)
- **Controllers:** PascalCase within namespaces (`Onboarding::CvUploadsController`)
- **Services:** Organized by domain (cv_extraction/, cv_parsing/, prefill/, completion/); module-wrapped classes; file names match directory structure
- **Jobs:** PascalCase (`ParseCandidateCvJob`, `CandidateWebhookJob`)
- **Initializers:** snake_case descriptive names (`admin_credentials_check.rb`, `app_config.rb`, `rack_attack.rb`)
- **Migrations:** Rails convention (timestamp + snake_case descriptor)

### JavaScript/Stimulus
- **Controllers:** kebab-case filenames (`cv_upload_controller.js`, `conditional_fields_controller.js`)
- **Stimulus identifiers:** Match filename base (e.g., `cv-upload` for `cv_upload_controller.js`)
- **Data attributes:** kebab-case on HTML (e.g., `data-cv-max-size`, `data-poll-interval`)

### CSS/Assets
- **Tailwind CSS:** Only. No custom CSS files for app logic; design system in `app/assets/stylesheets/design-system.css` (Tailwind + custom utilities)
- **Plain JS/CSS assets:** kebab-case (Rails importmap convention)

### Config Files
- `.env.example` — Template with all ENV vars (never commit `.env`)
- `config/recurring.yml` — Solid Queue schedule (YAML, production-only)
- `config/database.yml` — Two databases (primary + queue) per environment

## Rails Omakase & Linting

**Style guide:** Rails Omakase via `rubocop-rails-omakase` gem. Enforced on CI (pre-commit hooks not configured).
- Single quotes for strings (unless interpolation needed)
- 2-space indentation
- No trailing commas in method calls
- Prefer keyword arguments over positional
- Empty line between method definitions

**Security scanners:**
- `brakeman` — Static analysis for Rails vulnerabilities
- `bundler-audit` — Gem audit (see `config/bundler-audit.yml` for ignored issues)

## ActiveRecord Patterns

### Models
- **Validations:** Use `:draft` (default) and `:complete` contexts to defer required-field checks until final save
  ```ruby
  validates :first_name, presence: true, on: :complete
  ```
- **Enums:** Numeric-backed, prefixed for clarity
  ```ruby
  enum :big_status, { registered: 0, in_progress: 1, ... }, prefix: :big
  enum :status, { in_progress: 0, completed: 1 }, prefix: :profile
  ```
- **Nested attributes:** Use `accepts_nested_attributes_for` with `:reject_if` to skip blank rows
  ```ruby
  accepts_nested_attributes_for :educations, reject_if: :all_blank
  ```
- **Concerns:** Extract shared validations/logic (e.g., `CandidateConditionalValidations`)

### Strong Parameters
- Service-managed columns **never** whitelisted (e.g., `field_provenance`, `parsed_data`, `prefilled_at`)
- Nested attributes declared explicitly:
  ```ruby
  params.require(:candidate_profile).permit(
    :first_name, :last_name,
    candidate_languages_attributes: [:language_id, :level],
    educations_attributes: [:study, :institution, :_destroy]
  )
  ```

### Transactions & Locks
- **Atomicity:** Services wrap multi-step changes in `transaction` blocks
- **Race guards:** Use `with_lock` for concurrent-access protection (e.g., Completion::SaveProfile)
- **Idempotency:** Check state before re-running (e.g., PrefillService checks `prefilled_at`)

## Service Objects

**Pattern:** Stateless, single-responsibility, callable via `.call()` or instantiate + `call`.

```ruby
class PrefillService
  def initialize(profile, parsed)
    @profile = profile
    @parsed = parsed
  end

  def call
    return if @profile.prefilled?  # Idempotency check
    @profile.transaction do
      assign_scalars
      # ... more assignments
      @profile.save!
    end
  end
end
```

**Key principles:**
- Input validated on entry (fail fast)
- Side effects only after successful transaction
- Return meaningful result (not just boolean)
- Null/blank safety via `&.` and explicit checks

## Jobs & Background Processing

**Framework:** Solid Queue (ActiveJob backend). Database-backed queue tables in `db/queue_migrate/`.

**Patterns:**
- `queue_as :default` — All jobs use single default queue (priority handled elsewhere)
- `retry_on` / `discard_on` for error classification
- Perform method should be idempotent (safe to replay)
- Bail early if state already processed
  ```ruby
  def perform(candidate_document_id)
    document = CandidateDocument.find_by(id: candidate_document_id)
    return if document.nil? || document.completed? || document.failed?
  end
  ```

## Controllers

**Naming:** Nested namespaces match routes (Onboarding::CvUploadsController for `/onboarding/cv`).

**Patterns:**
- Minimal logic; delegate to services/models
- Session-based candidate tracking (`session[:candidate_profile_id]`)
- HTTP Basic auth for admin (`authenticate_with_http_basic` via Rack middleware)
- Render different views for state machine (upload/processing/completed/failed)

**Example:**
```ruby
def create
  return reject_upload("Consent required") unless consent_given?
  profile = current_candidate_profile || CandidateProfile.new
  ActiveRecord::Base.transaction do
    profile.save! or raise ActiveRecord::Rollback
    document = build_cv_document(profile)
    raise ActiveRecord::Rollback unless document.save
  end
  redirect_to onboarding_cv_upload_path
end
```

## View Templates

### ERB Escaping
- **Default:** Auto-escaped by Rails 8. No `raw()` on user data (breaks XSS protection)
- **Safe HTML:** Use partials for generated markup (e.g., badge partial)
  ```erb
  <%= render "onboarding/shared/badge", state: :cv %>
  ```
- **Form helpers:** Use Rails form helpers (auto-escaping + CSRF tokens)

### Stimulus Wiring
- Data attributes pass config to controllers
  ```html
  <div data-controller="cv-upload" data-cv-max-size="<%= CV_MAX_MB %>">
  ```
- Submit handlers → `prevent_default` + manual handling (not form HTML form behavior)

### Nested Forms
- Template element stores hidden row for cloning
  ```html
  <template data-target="nested-form.template">
    <%= render "education_row", education: Education.new, index: "INDEX" %>
  </template>
  ```

## Testing

**Framework:** Minitest (Rails default). No RSpec.

**Test structure:**
```ruby
class CandidateProfileTest < ActiveSupport::TestCase
  fixtures :candidate_profiles, :job_functions
  
  test "draft profile valid without required fields" do
    profile = CandidateProfile.new
    assert profile.valid?(:draft)
  end
  
  test "complete validation requires email" do
    profile = CandidateProfile.new(search_status: :active)
    refute profile.valid?(:complete)
    assert profile.errors[:email].present?
  end
end
```

**Fixtures:** YAML files in `test/fixtures/` (one per model). Seeded via Rails fixtures mechanism (auto-loaded in test setup).

**Mocking:** webmock stubs HTTP (Claude API calls):
```ruby
stub_request(:post, "https://api.anthropic.com/v1/messages").to_return(body: mock_response)
```

**System tests:** Capybara + Selenium for end-to-end flows:
```ruby
class OnboardingManualPathTest < ApplicationSystemTestCase
  test "candidate completes onboarding without CV parsing" do
    visit onboarding_cv_upload_path
    check "consent"
    click_button "Continue manually"
    assert_text "Review your profile"
  end
end
```

## Database & Migrations

**Primary DB:** Candidate profiles, educations, work experiences, skills, languages, regions, documents (all business data).

**Queue DB:** Solid Queue job tables (separate database for isolation, no lock contention with app queries).

**Schema patterns:**
- Foreign keys explicitly declared (Rails 8 default)
- Unique indexes where applicable (email, job_function key)
- JSONB columns for semi-structured data (`field_provenance`, `parsed_data`)
- Array columns for multi-select (working_days, transport_modes)
- Position columns for ordering nested records
- Enum columns use integer storage (parsing_status: 0=pending, 1=processing, etc.)

**Seeds:** `db/seeds.rb` uses `find_or_create_by` for idempotency (safe to re-run):
```ruby
Language.find_or_create_by(code: "nl", name: "Dutch")
```

## Environment Configuration

**Source:** `.env.example` (check into repo); runtime `.env` (never checked in).

**Key vars:**
- `ANTHROPIC_API_KEY` — Claude API authentication (required for parsing)
- `CLAUDE_MODEL` — Model name (default: `claude-sonnet-5`)
- `CV_MAX_SIZE_MB` — Upload limit in megabytes (default: 25)
- `ADMIN_USERNAME`, `ADMIN_PASSWORD`, `ADMIN_EMAIL` — HTTP Basic auth for /admin
- `WEBHOOK_URL` — Optional webhook endpoint on completion (must be operator-set)
- `APP_HOST` — Application hostname (used in emails, env-specific)
- `MAILER_FROM` — Email from address
- `DATABASE_URL` — (production only; Rails default)

**Loading:** via `dotenv-rails` (development/test) or Rails credentials (production).

## Security

### Active Storage
- **Private by default** — No public URLs for CVs
- **Validation:** spoofing_protection checks magic bytes (not client Content-Type)
- **Purge:** Cascades via `dependent: :destroy` on profile deletion

### HTTP Basic Auth
- Admin endpoints protected via middleware (check `app/controllers/admin/base_controller.rb`)
- Password validated at boot in production (`config/initializers/admin_credentials_check.rb`)

### Rate Limiting
- Rack::Attack middleware throttles CV uploads (10/hour per IP, 10/hour per session)
- Broader cap on all onboarding writes (60/hour per IP)
- Throttle responder returns 429 Too Many Requests

### Data Minimization
- Parsed AI output (`parsed_data`) cleared after prefill (never persisted)
- Stale profiles purged after 30 days (Solid Queue recurring job)
- Consent timestamp stored (simple audit trail)
- No merge on duplicate email (flagged for manual admin review)

### Validation & Sanitization
- Email regex validation (URI::MailTo::EMAIL_REGEXP)
- Phone validation via phonelib gem (Dutch + international)
- Phonelib normalizes to E.164 format
- Filesize check before blob creation
- Never trust client Content-Type; check magic bytes

## Conventional Commits

**Format:** `type(scope): message`

**Types used:**
- `feat` — New feature
- `fix` — Bug fix
- `docs` — Documentation updates
- `refactor` — Code restructuring (no functional change)
- `test` — Test additions/improvements
- `chore` — Build, deps, config (not code changes)

**Example:**
```
feat(cv-parsing): add Claude integration with retry logic
fix(prefill): skip if profile already prefilled
test(candidate-profile): add validation context tests
docs(deployment): add production setup guide
```

**No AI references in commit messages** (e.g., "assisted by Claude" — omit).

## Performance & Optimization

- **N+1 queries:** Eager-load associations in controllers (not enforced, but recommended)
- **Database indexes:** Present on foreign keys, unique constraints (status, email, parsing_status)
- **Polling vs. WebSocket:** Polling chosen for simplicity (2s interval, <5s parse time)
- **Timeouts:** Claude client 120s; stuck-processing guard 3min; file extraction 20s

## Anti-patterns to Avoid

1. **Calling services in views** — Move logic to controller/helper
2. **Raw on user input** — Always use safe partials or helpers
3. **Hardcoded secrets** — Use ENV vars, never commit `.env`
4. **Skipping validations for convenience** — Use `validates on: :complete` context instead
5. **Async without idempotency checks** — Always check state before re-running
6. **Forgetting `dependent: :destroy`** — Prevents orphaned records
7. **Service without transaction** — Multi-step changes must be atomic
