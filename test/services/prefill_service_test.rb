require "test_helper"

class PrefillServiceTest < ActiveSupport::TestCase
  fixtures :candidate_profiles, :job_functions, :regions, :languages, :employment_types, :skills

  def setup
    @profile = candidate_profiles(:john_doe)
    @profile.candidate_regions.clear
    @profile.candidate_languages.clear
    @profile.candidate_employment_types.clear
    @parsed = load_fixture("parsed_cv.json")
  end

  test "prefill service maps scalar fields" do
    PrefillService.new(@profile, @parsed).call

    assert_equal "Sanne", @profile.first_name
    assert_equal "de Vries", @profile.last_name
    assert_equal "sanne.devries@example.com", @profile.email
    assert_equal "Amsterdam", @profile.city
    assert_equal "Netherlands", @profile.country
    assert_equal 8, @profile.years_experience
    assert_equal "B001234567", @profile.big_number
    assert_equal "Experienced general dentist with focus on patient care and preventive dentistry", @profile.professional_summary
  end

  test "prefill service normalizes phone number" do
    PrefillService.new(@profile, @parsed).call
    assert_equal "+31612345678", @profile.phone
  end

  test "prefill service sets prefilled_at timestamp" do
    PrefillService.new(@profile, @parsed).call
    assert @profile.prefilled_at.present?
  end

  test "prefill service records field provenance" do
    PrefillService.new(@profile, @parsed).call

    assert_equal(
      { "source" => "cv", "confidence" => "high" },
      @profile.provenance_for(:first_name)
    )
    assert_equal(
      { "source" => "cv", "confidence" => "high" },
      @profile.provenance_for(:email)
    )
  end

  test "prefill service is idempotent - skips if already prefilled" do
    PrefillService.new(@profile, @parsed).call
    original_name = @profile.first_name
    original_prefilled_at = @profile.prefilled_at

    @profile.reload
    PrefillService.new(@profile, @parsed).call

    assert_equal original_name, @profile.first_name
    assert_equal original_prefilled_at, @profile.prefilled_at
  end

  test "prefill service assigns job function" do
    PrefillService.new(@profile, @parsed).call
    assert_equal job_functions(:general_dentist), @profile.job_function
  end

  test "prefill service assigns languages" do
    PrefillService.new(@profile, @parsed).call

    assert_equal 2, @profile.candidate_languages.count
    dutch = @profile.candidate_languages.find { |cl| cl.language.name == "Dutch" }
    english = @profile.candidate_languages.find { |cl| cl.language.name == "English" }

    assert dutch.present?
    assert english.present?
    assert_equal "native", dutch.level
    assert_equal "C1", english.level
  end

  test "prefill service skips unknown languages" do
    parsed = @parsed.dup
    parsed["languages"] = [
      { "name" => { "value" => "Klingon", "confidence" => "high" }, "level" => { "value" => "A1", "confidence" => "high" } }
    ]

    PrefillService.new(@profile, parsed).call
    assert_empty @profile.candidate_languages
  end

  test "prefill service builds educations" do
    PrefillService.new(@profile, @parsed).call

    assert_equal 1, @profile.educations.count
    education = @profile.educations.first

    assert_equal "Dentistry", education.study
    assert_equal "University of Amsterdam", education.institution
    assert_equal "Amsterdam", education.location
    assert_equal "Bachelor", education.level
    assert_equal Date.new(2012, 9, 1), education.start_date
    assert_equal Date.new(2016, 6, 1), education.end_date
  end

  test "prefill service builds work experiences" do
    PrefillService.new(@profile, @parsed).call

    assert_equal 2, @profile.work_experiences.count

    current = @profile.work_experiences.find { |we| we.current_job }
    assert_equal "General Dentist", current.job_title
    assert_equal "Smile Clinic Amsterdam", current.company_name
    assert_nil current.end_date

    past = @profile.work_experiences.find { |we| !we.current_job }
    assert_equal "Dental Assistant", past.job_title
    assert_equal Date.new(2017, 12, 1), past.end_date
  end

  test "prefill service sets big_status" do
    PrefillService.new(@profile, @parsed).call
    assert @profile.big_registered?
  end

  test "prefill service handles unknown skills" do
    parsed = @parsed.dup
    parsed["skills"] = [
      { "name" => { "value" => "Dental diagnostics", "confidence" => "high" } },
      { "name" => { "value" => "Unknown Skill", "confidence" => "medium" } }
    ]

    PrefillService.new(@profile, parsed).call

    assert_includes @profile.suggested_skills, "Unknown Skill"
  end

  test "prefill service saves profile" do
    refute @profile.prefilled_at.present?
    PrefillService.new(@profile, @parsed).call

    assert @profile.persisted?
    assert @profile.prefilled_at.present?
  end

  test "sparse fixture with null values never invents data" do
    sparse = {
      "first_name" => { "value" => "John", "confidence" => "high" },
      "last_name" => { "value" => "Doe", "confidence" => "high" },
      "email" => { "value" => nil, "confidence" => "high" },
      "phone" => { "value" => nil, "confidence" => "high" },
      "city" => { "value" => nil, "confidence" => "high" },
      "country" => { "value" => nil, "confidence" => "high" },
      "languages" => [],
      "skills" => [],
      "educations" => [],
      "work_experiences" => []
    }

    @profile.candidate_regions.clear
    @profile.candidate_languages.clear
    @profile.candidate_employment_types.clear

    PrefillService.new(@profile, sparse).call

    assert_equal "John", @profile.first_name
    assert_equal "Doe", @profile.last_name
  end

  private

  def load_fixture(name)
    path = Rails.root.join("test/fixtures/#{name}")
    JSON.parse(File.read(path))
  end
end
