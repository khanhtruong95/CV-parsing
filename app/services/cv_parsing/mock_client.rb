module CvParsing
  # Stand-in for ClaudeClient in development when no API key is configured.
  # Returns a fixed sample candidate so the whole flow can be demoed offline.
  class MockClient
    def extract(_extracted)
      sleep 1.5
      SAMPLE
    end

    def self.scalar(value, confidence = "high")
      { "value" => value, "confidence" => confidence }
    end

    SAMPLE = {
      "first_name" => scalar("Sanne"),
      "last_name" => scalar("de Vries"),
      "email" => scalar("sanne.devries@example.com"),
      "phone" => scalar("06 12 34 56 78", "medium"),
      "city" => scalar("Amsterdam"),
      "country" => scalar("Netherlands", "low"),
      "current_job_title" => scalar("Tandarts"),
      "dental_job_function" => scalar("tandarts", "medium"),
      "years_experience" => scalar(8, "medium"),
      "big_number" => scalar("39912345678"),
      "big_status" => scalar("registered", "medium"),
      "professional_summary" => scalar("Experienced general dentist with a focus on restorative care and patient education.", "medium"),
      "languages" => [
        { "name" => scalar("Nederlands"), "level" => scalar("moedertaal") },
        { "name" => scalar("English"), "level" => scalar("B2", "medium") }
      ],
      "skills" => [
        { "name" => scalar("Endodontics") },
        { "name" => scalar("Restorative dentistry", "medium") },
        { "name" => scalar("Laser whitening", "low") }
      ],
      "educations" => [
        { "institution" => scalar("ACTA"), "study" => scalar("Master Tandheelkunde"),
          "location" => scalar("Amsterdam", "medium"), "level" => scalar("Master", "medium"),
          "start_date" => scalar("2012-09"), "end_date" => scalar("2018-07", "medium") },
        { "institution" => scalar("ACTA"), "study" => scalar("Bachelor Tandheelkunde"),
          "location" => scalar("Amsterdam", "medium"), "level" => scalar("Bachelor", "medium"),
          "start_date" => scalar("2009-09", "medium"), "end_date" => scalar("2012-07", "medium") }
      ],
      "work_experiences" => [
        { "job_title" => scalar("Tandarts"), "company_name" => scalar("Tandartspraktijk Zuidas"),
          "responsibilities" => scalar("Full patient care: check-ups, restorative treatments and endodontics.", "medium"),
          "start_date" => scalar("2020-03"), "end_date" => scalar(nil, "low"),
          "current_job" => scalar(true) },
        { "job_title" => scalar("Associate Dentist"), "company_name" => scalar("Dental Clinics Haarlem"),
          "responsibilities" => scalar("General dentistry with a focus on preventive care.", "medium"),
          "start_date" => scalar("2018-08", "medium"), "end_date" => scalar("2020-02", "medium"),
          "current_job" => scalar(false) }
      ]
    }.freeze
  end
end
