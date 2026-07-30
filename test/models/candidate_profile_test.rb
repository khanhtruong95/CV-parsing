require "test_helper"

class CandidateProfileTest < ActiveSupport::TestCase
  fixtures :candidate_profiles, :candidate_documents, :job_functions, :regions, :languages, :employment_types

  test "draft profile is valid without required fields" do
    profile = CandidateProfile.new(
      job_function: job_functions(:general_dentist),
      search_status: :active
    )
    assert profile.valid?(:draft), "Draft profile should be valid without most fields"
  end

  test "complete validation requires first_name and last_name" do
    profile = CandidateProfile.new(search_status: :active)
    refute profile.valid?(:complete)
    assert_includes profile.errors[:first_name], I18n.t("errors.messages.blank")
    assert_includes profile.errors[:last_name], I18n.t("errors.messages.blank")
  end

  test "complete validation requires email with valid format" do
    profile = CandidateProfile.new(
      first_name: "John",
      last_name: "Doe",
      search_status: :active
    )
    refute profile.valid?(:complete), "Email is required"
    assert profile.errors[:email].present?, "Email should have errors"

    profile.email = "valid@example.com"
    profile.valid?(:complete)
    assert_empty profile.errors[:email], "Valid email format should pass"
  end

  test "complete validation requires phone with valid format" do
    profile = CandidateProfile.new(
      first_name: "John",
      last_name: "Doe",
      email: "john@example.com"
    )
    refute profile.valid?(:complete)
    assert_includes profile.errors[:phone], I18n.t("errors.messages.blank")
  end

  test "complete validation requires city and available_from" do
    profile = CandidateProfile.new(
      first_name: "John",
      last_name: "Doe",
      email: "john@example.com",
      phone: "+31612345678",
      job_function: job_functions(:general_dentist),
      search_status: :active
    )
    refute profile.valid?(:complete)
    assert profile.errors[:city].present?, "city should have errors"
    assert profile.errors[:available_from].present?, "available_from should have errors"
  end

  test "complete validation requires years_experience and max_travel_time as integers" do
    profile = build_valid_profile(years_experience: nil, max_travel_time: nil)
    refute profile.valid?(:complete)
    assert_includes profile.errors[:years_experience], I18n.t("errors.messages.blank")
    assert_includes profile.errors[:max_travel_time], I18n.t("errors.messages.blank")
  end

  test "complete validation requires at least one region" do
    profile = build_valid_profile
    profile.candidate_regions.clear
    refute profile.valid?(:complete)
    assert_includes profile.errors[:regions], "must include at least one region"
  end

  test "complete validation requires at least one language" do
    profile = build_valid_profile
    profile.candidate_languages.clear
    refute profile.valid?(:complete)
    assert_includes profile.errors[:languages], "must include at least one language"
  end

  test "complete validation requires at least one employment_type" do
    profile = build_valid_profile
    profile.candidate_employment_types.clear
    refute profile.valid?(:complete)
    assert_includes profile.errors[:employment_types], "must include at least one employment type"
  end

  test "complete validation requires at least one working day" do
    profile = build_valid_profile(working_days: [])
    refute profile.valid?(:complete)
    assert_includes profile.errors[:working_days], "must include at least one working day"
  end

  test "salary is required only when salary_based employment type is selected" do
    profile = build_valid_profile
    salary_based = employment_types(:salary_based)
    profile.employment_types = [ salary_based ]
    profile.desired_salary = nil

    refute profile.valid?(:complete), "Salary required for salary-based employment"
    assert profile.errors[:desired_salary].present?

    profile.desired_salary = 2500
    profile.valid?(:complete)
    assert_empty profile.errors[:desired_salary]
  end

  test "salary is not required when only flexible employment type selected" do
    profile = build_valid_profile
    flexible = employment_types(:flexible)
    profile.employment_types = [ flexible ]
    profile.desired_salary = nil

    profile.valid?(:complete)
    assert_empty profile.errors[:desired_salary]
  end

  test "percentage is required only when percentage_based employment type selected" do
    profile = build_valid_profile
    percentage_based = employment_types(:percentage_based)
    profile.employment_types = [ percentage_based ]
    profile.desired_percentage = nil

    refute profile.valid?(:complete), "Percentage required for percentage-based employment"
    assert profile.errors[:desired_percentage].present?

    profile.desired_percentage = 50
    profile.valid?(:complete)
    assert_empty profile.errors[:desired_percentage]
  end

  test "percentage must be between 0 and 100" do
    profile = build_valid_profile
    percentage_based = employment_types(:percentage_based)
    profile.employment_types = [ percentage_based ]

    profile.desired_percentage = -1
    refute profile.valid?(:complete), "Percentage must be >= 0"

    profile.desired_percentage = 101
    refute profile.valid?(:complete), "Percentage must be <= 100"

    profile.desired_percentage = 50
    profile.valid?(:complete)
    assert_empty profile.errors[:desired_percentage]
  end

  test "big_status is required only for job functions requiring BIG" do
    profile = build_valid_profile
    big_required_function = job_functions(:dentist_big_required)
    profile.job_function = big_required_function
    profile.big_status = nil

    refute profile.valid?(:complete)
    assert_includes profile.errors[:big_status], I18n.t("errors.messages.blank")

    profile.big_status = :registered
    profile.valid?(:complete)
    assert_empty profile.errors[:big_status]
  end

  test "big_number is required only when function requires BIG and status is registered" do
    profile = build_valid_profile
    big_required_function = job_functions(:dentist_big_required)
    profile.job_function = big_required_function
    profile.big_status = :registered
    profile.big_number = nil

    refute profile.valid?(:complete)
    assert_includes profile.errors[:big_number], I18n.t("errors.messages.blank")

    profile.big_number = "B001234567"
    profile.valid?(:complete)
    assert_empty profile.errors[:big_number]
  end

  test "big_number is not required when status is not registered" do
    profile = build_valid_profile
    big_required_function = job_functions(:dentist_big_required)
    profile.job_function = big_required_function
    profile.big_status = :in_progress
    profile.big_number = nil

    profile.valid?(:complete)
    assert_empty profile.errors[:big_number]
  end

  test "daily_revenue is required only for job functions requiring it" do
    profile = build_valid_profile
    daily_revenue_function = job_functions(:daily_revenue_required)
    profile.job_function = daily_revenue_function
    profile.average_daily_revenue = nil

    refute profile.valid?(:complete)
    assert_includes profile.errors[:average_daily_revenue], I18n.t("errors.messages.blank")

    profile.average_daily_revenue = 300
    profile.valid?(:complete)
    assert_empty profile.errors[:average_daily_revenue]
  end

  test "provenance_for returns field source and confidence" do
    profile = build_valid_profile
    profile.field_provenance = {
      "first_name" => { "source" => "cv", "confidence" => "high" },
      "email" => { "source" => "cv", "confidence" => "low" }
    }
    profile.save!

    assert_equal(
      { "source" => "cv", "confidence" => "high" },
      profile.provenance_for(:first_name)
    )
    assert_equal(
      { "source" => "cv", "confidence" => "low" },
      profile.provenance_for(:email)
    )
    assert_equal({}, profile.provenance_for(:unknown_field))
  end

  test "prefilled? returns true only when prefilled_at is present" do
    profile = build_valid_profile(prefilled_at: nil)
    refute profile.prefilled?

    profile.prefilled_at = Time.current
    assert profile.prefilled?
  end

  test "latest_cv_document queries documents correctly" do
    profile = candidate_profiles(:john_doe)
    result = profile.candidate_documents.where(document_type: "cv").order(:created_at).last
    if result.nil?
      assert_nil profile.latest_cv_document
    else
      assert_equal result, profile.latest_cv_document
    end
  end

  test "full_name combines first and last name" do
    profile = CandidateProfile.new(first_name: "John", last_name: "Doe")
    assert_equal "John Doe", profile.full_name

    profile = CandidateProfile.new(first_name: "John", last_name: nil)
    assert_equal "John", profile.full_name

    profile = CandidateProfile.new(first_name: nil, last_name: "Doe")
    assert_equal "Doe", profile.full_name
  end

  test "search_status enum values" do
    profile = CandidateProfile.new
    assert profile.respond_to?(:active?)
    assert profile.respond_to?(:passive?)
    assert profile.respond_to?(:inactive?)
  end

  test "big_status enum values" do
    profile = CandidateProfile.new
    assert profile.respond_to?(:big_registered?)
    assert profile.respond_to?(:big_in_progress?)
  end

  test "status enum values" do
    profile = CandidateProfile.new
    assert profile.respond_to?(:profile_in_progress?)
    assert profile.respond_to?(:profile_completed?)
  end

  private

  def build_valid_profile(overrides = {})
    defaults = {
      first_name: "John",
      last_name: "Doe",
      email: "john@example.com",
      phone: "+31612345678",
      city: "Amsterdam",
      country: "Netherlands",
      job_function: job_functions(:general_dentist),
      search_status: :active,
      available_from: 1.week.from_now,
      years_experience: 5,
      max_travel_time: 30,
      working_days: %w[monday tuesday wednesday thursday friday],
      field_provenance: {},
      desired_salary: 2500
    }
    attrs = defaults.merge(overrides)
    profile = CandidateProfile.new(attrs)
    profile.candidate_regions.build(region: regions(:amsterdam))
    profile.candidate_languages.build(language: languages(:dutch), level: :native)
    profile.candidate_employment_types.build(employment_type: employment_types(:employed))
    profile
  end
end
