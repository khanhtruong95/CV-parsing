# PRD — Candidate Onboarding with CV Upload (DentaMatch)

Source: client PRD, received 2026-07-11. Verbatim requirements, lightly reformatted.

## 1. Overview

Candidate onboarding flow for a dental recruitment platform, built in Ruby on Rails (or Rails-compatible module design). Two steps: (1) Upload CV, (2) Review and complete profile. Purpose: reduce manual input — system extracts as much as possible from the CV; candidate checks, corrects, completes.

## 2. User Flow

### Step 1 — CV Upload
Copy: "Upload your CV. We will automatically fill in as much of your candidate profile as possible. You can review and edit everything before saving."
- Supported types: PDF, DOC, DOCX. Max size configurable (suggested 25 MB+).
- After upload, system extracts candidate data; show loading state while processing.
- If CV cannot be parsed, candidate can continue manually.

### Step 2 — Review and Complete Profile
Prefilled form. Candidate can: review/edit all data, complete missing fields, add extra education/work-experience records, select skills, save. Not-found fields stay empty and clearly visible as needing input. Uncertain extracted fields marked ("Please check" / "Extracted from CV" / "Missing"). Keep UI simple — do not overbuild.

## 3. Candidate Profile Fields

### 3.1 Personal Details
| Field | Type | Required | From CV |
|---|---|---|---|
| First name | Text | Yes | Yes |
| Last name | Text | Yes | Yes |
| Email | Email | Yes | Yes |
| Phone number | Text (intl formats) | Yes | Yes |
| City / residence | Text | Yes | Yes |
| Country | Text/select | Should | Yes |
| Languages | Multi-select (+ level e.g. B2/fluent/native) | Yes | Yes |

### 3.2 Job Preferences
| Field | Type | Required | From CV |
|---|---|---|---|
| Desired job function | Single select (fixed categories) | Yes | Partly |
| Preferred regions | Multi-select | Yes | No/partly |
| Maximum travel time | Number | Yes | No |
| Transport type | Multi-select (Bike, Scooter, Public transport, Car) | No | No/partly |
| Search status | Single select (Active, Passive, Inactive) | Yes | No |
| Reason for looking | Text | No | No/partly |

Job function = fixed platform categories (no free-text primary function; needed for matching): General dentist, Dental hygienist, Dental assistant, Prevention assistant, Paro-prevention assistant, Orthodontic assistant, Front-office / receptionist, Practice manager, Dental technician, Specialist.

### 3.3 Employment and Compensation
| Field | Type | Required | Condition |
|---|---|---|---|
| Desired employment type | Multi-select | Yes | Always |
| Desired gross salary | Number | Conditional | If employed |
| Desired percentage | Number (0–100) | Conditional | If self-employed / revenue-based |
| Average daily revenue | Number | Conditional | Dentists/hygienists/specialists/prevention assistant |
| BIG registration status | Select (BIG registered, In progress, Under supervision, Not applicable) | Conditional | Dentists/specialists (also hygienist per §4) |
| BIG number | Text/number | Conditional | If BIG registered |
| Years of combined dental experience | Number ≥0 | Yes | Always |

### 3.4 Education (repeater; add/edit/remove; parser prefills)
Institution (No), Study/course (Yes), City+country (No), Level select MBO/HBO/Bachelor/Master/Doctor/Course (No), Start date (No), End date (No).

### 3.5 Work Experience (repeater; multiple jobs; separate records; parser prefills)
Job title (Yes), Company name (Yes), Responsibilities textarea (No), Start date (No), End date (No), Current job boolean (No).

### 3.6 Skills
Shown based on selected job function; skill groups per function (Dentist: endodontics, restorative, pediatric, surgery, aligners; Hygienist: periodontology, prevention, scaling, patient education; Assistant: chairside assistance, sterilization, orthodontics, prevention; Front-office: planning, phone handling, invoicing, patient communication; Practice manager: team management, scheduling, HR, practice operations; Technician: prosthetics, CAD/CAM, crown and bridge work). Candidate selects; parser detects and matches to platform list; unknown skills stored as free-text suggestions for recruiter review.

### 3.7 Availability
Available working days multi-select Mon–Sun (Yes), Available from date (Yes), Notice period number/text (No).

### 3.8 Additional Information
Motivation for employer (textarea, No), Internal notes for recruitment team (textarea, No — candidate-entered only), Reason for looking (text, No). System may generate suggested professional summary from CV; candidate must be able to edit before save.

## 4. Conditional Form Logic
- Function ∈ {dentist, dental hygienist, specialist}: show BIG registration, average daily revenue, desired percentage (if self-employed/percentage-based), relevant clinical skills.
- Function = dental assistant / front-office / practice manager / dental technician: hide BIG registration; show respective skill group.
- Employment type includes employed → show desired salary. Includes self-employed/freelance/percentage-based → show desired percentage.

## 5. CV Parsing Requirements
Extract: name, email, phone, city, country, languages, current/recent job title, relevant dental job function, education history, work experience history, skills, BIG number/status, years of experience, professional summary.
Rules: never invent missing info (leave empty); candidate always reviews before save; uncertain fields marked for review; Dutch + English CVs minimum (ideally common European dental formats). Internal parse format is developer's choice as long as it prefills reliably.

## 6. Data Model (suggested)
User has_one CandidateProfile. CandidateProfile has_many: candidate_documents, educations, work_experiences, candidate_skills (skills through), candidate_languages (languages through). CandidateDocument: belongs_to profile, has_one_attached file, document_type: cv, original_filename, content_type, file_size, parsed_at, parsing_status (pending/processing/completed/failed). Active Storage preferred; parsing in background job (ParseCandidateCvJob).

## 7. Main Screens
7.1 Upload: explanation, drag-and-drop, type info, upload button, processing state, parse-fail error + continue manually. Buttons: "Upload CV", "Analyze CV", "Continue manually".
7.2 Review: 8 editable sections (personal, preferences, employment, education, experience, skills, availability, additional). Save only when required fields valid.

## 8. Validation Rules
Email valid; phone Dutch + intl; CV type PDF/DOC/DOCX; size configurable (25 MB+ suggested); function required; ≥1 region; city required; max travel time required numeric; ≥1 employment type; years experience numeric ≥0; salary numeric (when shown); percentage 0–100; daily revenue numeric; BIG number required iff status=registered; ≥1 working day; available-from valid date.

## 9. Privacy & Security
CVs not publicly accessible; only candidate + authorized admins/recruiters view; consent checkbox before upload/save ("I agree that my CV and profile information may be processed to create and improve my candidate profile."); never expose raw AI/parser output to candidates; store only data needed for recruitment/matching.

## 10. Notifications & Follow-up
On submit: save profile, CV, education, experience, skills; notify admin/recruitment team; optional webhook `candidate_onboarding_completed` (payload developer's choice; not mandatory for MVP).

## 11. Error Handling
Unsupported type / too large → clear error. Upload fails → retry. Parse fails → manual onboarding. Sparse CV → prefill available, rest empty. Page closed during parsing → save upload, allow resume. Wrong extraction → editable. Incomplete submit → validation errors.

## 12. Acceptance Criteria (summary)
Upload: PDF/DOC/DOCX accepted, size limit enforced, invalid rejected, private storage, manual fallback. Parsing: extracts available data, never invents, maps to correct fields, all editable, NL+EN supported. Form: all fields present, conditional logic works, multi-record education/experience, skills by function, required-field validation. Saving: profile+CV+records+skills+languages persisted, admin can view completed profile.

## 13. MVP Scope
IN: two-step flow, upload, parsing, prefill, manual correction, conditional fields, education/experience repeaters, skills by function, private storage, admin notification.
OUT: completeness score, duplicate detection, automatic BIG validation, AI debug dashboard, multilingual UI, automatic matching, complex privacy workflows, detailed AI schema in PRD.

## 14. Technical Notes
Maintainable onboarding module, not one hardcoded form. CandidateProfile main object; Education/WorkExperience nested resources; Active Storage; background parsing job with status; form options (functions, regions, employment types, skills, languages) DB/admin-manageable; candidate can edit all parsed fields before final save.
