# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_07_11_050330) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "candidate_documents", force: :cascade do |t|
    t.bigint "candidate_profile_id", null: false
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "document_type", default: "cv", null: false
    t.string "failure_reason"
    t.bigint "file_size"
    t.string "original_filename"
    t.datetime "parsed_at"
    t.jsonb "parsed_data", default: {}, null: false
    t.integer "parsing_status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["candidate_profile_id"], name: "index_candidate_documents_on_candidate_profile_id"
    t.index ["parsing_status"], name: "index_candidate_documents_on_parsing_status"
  end

  create_table "candidate_employment_types", force: :cascade do |t|
    t.bigint "candidate_profile_id", null: false
    t.datetime "created_at", null: false
    t.bigint "employment_type_id", null: false
    t.datetime "updated_at", null: false
    t.index ["candidate_profile_id", "employment_type_id"], name: "index_candidate_employment_types_uniqueness", unique: true
    t.index ["candidate_profile_id"], name: "index_candidate_employment_types_on_candidate_profile_id"
    t.index ["employment_type_id"], name: "index_candidate_employment_types_on_employment_type_id"
  end

  create_table "candidate_languages", force: :cascade do |t|
    t.bigint "candidate_profile_id", null: false
    t.datetime "created_at", null: false
    t.bigint "language_id", null: false
    t.string "level"
    t.datetime "updated_at", null: false
    t.index ["candidate_profile_id", "language_id"], name: "idx_on_candidate_profile_id_language_id_e7df01ffda"
    t.index ["candidate_profile_id"], name: "index_candidate_languages_on_candidate_profile_id"
    t.index ["language_id"], name: "index_candidate_languages_on_language_id"
  end

  create_table "candidate_profiles", force: :cascade do |t|
    t.date "available_from"
    t.integer "average_daily_revenue"
    t.string "big_number"
    t.integer "big_status"
    t.string "city"
    t.datetime "completed_at"
    t.datetime "consent_accepted_at"
    t.string "country", default: "Netherlands"
    t.datetime "created_at", null: false
    t.integer "desired_percentage"
    t.integer "desired_salary"
    t.boolean "duplicate_email", default: false, null: false
    t.string "email"
    t.jsonb "field_provenance", default: {}, null: false
    t.string "first_name"
    t.text "internal_notes"
    t.bigint "job_function_id"
    t.string "last_name"
    t.integer "max_travel_time"
    t.text "motivation"
    t.string "notice_period"
    t.string "phone"
    t.datetime "prefilled_at"
    t.text "professional_summary"
    t.text "reason_for_looking"
    t.integer "search_status", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.text "suggested_skills"
    t.string "transport_modes", default: [], array: true
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.string "working_days", default: [], array: true
    t.integer "years_experience"
    t.index ["email"], name: "index_candidate_profiles_on_email"
    t.index ["job_function_id"], name: "index_candidate_profiles_on_job_function_id"
    t.index ["status"], name: "index_candidate_profiles_on_status"
    t.index ["user_id"], name: "index_candidate_profiles_on_user_id"
  end

  create_table "candidate_regions", force: :cascade do |t|
    t.bigint "candidate_profile_id", null: false
    t.datetime "created_at", null: false
    t.bigint "region_id", null: false
    t.datetime "updated_at", null: false
    t.index ["candidate_profile_id", "region_id"], name: "index_candidate_regions_on_candidate_profile_id_and_region_id", unique: true
    t.index ["candidate_profile_id"], name: "index_candidate_regions_on_candidate_profile_id"
    t.index ["region_id"], name: "index_candidate_regions_on_region_id"
  end

  create_table "candidate_skills", force: :cascade do |t|
    t.bigint "candidate_profile_id", null: false
    t.datetime "created_at", null: false
    t.bigint "skill_id", null: false
    t.datetime "updated_at", null: false
    t.index ["candidate_profile_id", "skill_id"], name: "index_candidate_skills_on_candidate_profile_id_and_skill_id", unique: true
    t.index ["candidate_profile_id"], name: "index_candidate_skills_on_candidate_profile_id"
    t.index ["skill_id"], name: "index_candidate_skills_on_skill_id"
  end

  create_table "educations", force: :cascade do |t|
    t.bigint "candidate_profile_id", null: false
    t.datetime "created_at", null: false
    t.date "end_date"
    t.string "institution"
    t.string "level"
    t.string "location"
    t.integer "position", default: 0, null: false
    t.date "start_date"
    t.string "study"
    t.datetime "updated_at", null: false
    t.index ["candidate_profile_id"], name: "index_educations_on_candidate_profile_id"
  end

  create_table "employment_types", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "key"
    t.string "name", null: false
    t.boolean "percentage_based", default: false, null: false
    t.integer "position", default: 0, null: false
    t.boolean "salary_based", default: false, null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_employment_types_on_key", unique: true
  end

  create_table "job_functions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "key", null: false
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.boolean "requires_big", default: false, null: false
    t.boolean "requires_daily_revenue", default: false, null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_job_functions_on_key", unique: true
  end

  create_table "languages", force: :cascade do |t|
    t.string "code"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_languages_on_code", unique: true
  end

  create_table "regions", force: :cascade do |t|
    t.string "code"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_regions_on_name", unique: true
  end

  create_table "skills", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_function_id", null: false
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["job_function_id", "name"], name: "index_skills_on_job_function_id_and_name", unique: true
    t.index ["job_function_id"], name: "index_skills_on_job_function_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "first_name"
    t.string "last_name"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  create_table "work_experiences", force: :cascade do |t|
    t.bigint "candidate_profile_id", null: false
    t.string "company_name"
    t.datetime "created_at", null: false
    t.boolean "current_job", default: false, null: false
    t.date "end_date"
    t.string "job_title"
    t.integer "position", default: 0, null: false
    t.text "responsibilities"
    t.date "start_date"
    t.datetime "updated_at", null: false
    t.index ["candidate_profile_id"], name: "index_work_experiences_on_candidate_profile_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "candidate_documents", "candidate_profiles"
  add_foreign_key "candidate_employment_types", "candidate_profiles"
  add_foreign_key "candidate_employment_types", "employment_types"
  add_foreign_key "candidate_languages", "candidate_profiles"
  add_foreign_key "candidate_languages", "languages"
  add_foreign_key "candidate_profiles", "job_functions"
  add_foreign_key "candidate_profiles", "users"
  add_foreign_key "candidate_regions", "candidate_profiles"
  add_foreign_key "candidate_regions", "regions"
  add_foreign_key "candidate_skills", "candidate_profiles"
  add_foreign_key "candidate_skills", "skills"
  add_foreign_key "educations", "candidate_profiles"
  add_foreign_key "skills", "job_functions"
  add_foreign_key "work_experiences", "candidate_profiles"
end
