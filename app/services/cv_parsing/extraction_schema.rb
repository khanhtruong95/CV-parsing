module CvParsing
  module ExtractionSchema
    TOOL_NAME = "candidate_profile".freeze

    SYSTEM_PROMPT = <<~PROMPT.freeze
      You extract candidate data from a CV for a Dutch dental recruitment platform.
      Extract ONLY what is explicitly present in the CV. NEVER invent, infer beyond
      the text, or guess. For anything not present, set value to null. For each field
      give a confidence: "high" (explicit and unambiguous), "medium" (present but
      ambiguous or needs formatting), "low" (weak inference). CVs may be written in
      Dutch or English. Dates: return ISO format YYYY-MM or YYYY-MM-DD where known,
      otherwise null. Respond only via the candidate_profile tool.
    PROMPT

    CONFIDENCE = { "type" => "string", "enum" => %w[high medium low] }.freeze

    def self.scalar(type = "string", extra = {})
      {
        "type" => "object",
        "properties" => {
          "value" => { "type" => [ type, "null" ] }.merge(extra),
          "confidence" => CONFIDENCE
        },
        "required" => %w[value confidence]
      }
    end

    def self.record(fields)
      {
        "type" => "object",
        "properties" => fields,
        "required" => fields.keys
      }
    end

    INPUT = {
      "type" => "object",
      "properties" => {
        "first_name" => scalar, "last_name" => scalar,
        "email" => scalar, "phone" => scalar,
        "city" => scalar, "country" => scalar,
        "current_job_title" => scalar,
        "dental_job_function" => scalar,
        "years_experience" => scalar("integer"),
        "big_number" => scalar,
        "big_status" => scalar("string", "enum" => [ "registered", "in_progress", "under_supervision", "not_applicable", nil ]),
        "professional_summary" => scalar,
        "languages" => { "type" => "array", "items" => record("name" => scalar, "level" => scalar) },
        "skills" => { "type" => "array", "items" => record("name" => scalar) },
        "educations" => {
          "type" => "array",
          "items" => record(
            "institution" => scalar, "study" => scalar, "location" => scalar,
            "level" => scalar, "start_date" => scalar, "end_date" => scalar
          )
        },
        "work_experiences" => {
          "type" => "array",
          "items" => record(
            "job_title" => scalar, "company_name" => scalar, "responsibilities" => scalar,
            "start_date" => scalar, "end_date" => scalar, "current_job" => scalar("boolean")
          )
        }
      },
      "required" => %w[first_name last_name email phone city country current_job_title
                       dental_job_function years_experience big_number big_status
                       professional_summary languages skills educations work_experiences]
    }.freeze
  end
end
