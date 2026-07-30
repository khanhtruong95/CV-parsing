require "test_helper"

class Completion::SaveProfileTest < ActiveSupport::TestCase
  fixtures :candidate_profiles, :users, :job_functions, :regions, :languages, :employment_types

  def setup
    @profile = build_valid_profile
  end

  test "save_profile returns failure when profile is invalid" do
    @profile.first_name = nil
    result = Completion::SaveProfile.new(@profile).call

    refute result.success?
    assert_equal @profile, result.profile
  end

  test "save_profile returns success when profile is valid" do
    result = Completion::SaveProfile.new(@profile).call

    assert result.success?
    assert_equal @profile, result.profile
  end

  test "save_profile creates new user when email is unused" do
    email = "newuser@example.com"
    @profile.email = email
    refute User.exists?(email: email)

    result = Completion::SaveProfile.new(@profile).call

    assert result.success?
    assert @profile.user.present?
    assert_equal email, @profile.user.email
    assert_equal @profile.first_name, @profile.user.first_name
    assert_equal @profile.last_name, @profile.user.last_name
    refute @profile.duplicate_email
  end

  test "save_profile does not create user when email exists" do
    existing_user = users(:alice)
    @profile.email = existing_user.email

    result = Completion::SaveProfile.new(@profile).call

    assert result.success?
    assert_nil @profile.user
    assert @profile.duplicate_email
  end

  test "save_profile marks duplicate_email when email conflict" do
    existing_user = users(:alice)
    @profile.email = existing_user.email

    Completion::SaveProfile.new(@profile).call

    assert @profile.duplicate_email
  end

  test "save_profile marks profile as completed" do
    result = Completion::SaveProfile.new(@profile).call

    assert result.success?
    @profile.reload
    assert @profile.profile_completed?
  end

  test "save_profile sets completed_at timestamp" do
    result = Completion::SaveProfile.new(@profile).call

    assert result.success?
    @profile.reload
    assert @profile.completed_at.present?
  end

  test "save_profile completes profile successfully" do
    result = Completion::SaveProfile.new(@profile).call

    assert result.success?
    @profile.reload
    assert @profile.profile_completed?
    assert @profile.completed_at.present?
  end

  test "save_profile is idempotent - double submit produces one completion" do
    Completion::SaveProfile.new(@profile).call
    first_completed_at = @profile.completed_at

    @profile.reload
    Completion::SaveProfile.new(@profile).call

    assert_equal first_completed_at, @profile.completed_at
  end

  test "save_profile persists candidate edits before completing" do
    @profile.years_experience = 10
    result = Completion::SaveProfile.new(@profile).call

    assert result.success?
    @profile.reload
    assert_equal 10, @profile.years_experience
  end

  test "save_profile returns failure when validation fails without side effects" do
    @profile.first_name = nil
    initial_completed = @profile.profile_completed?

    result = Completion::SaveProfile.new(@profile).call

    refute result.success?
    assert_equal initial_completed, @profile.profile_completed?
  end

  test "save_profile handles RecordNotUnique error gracefully" do
    @profile.save!

    @profile.with_lock do
      @profile.update!(status: :completed, completed_at: Time.current)
    end

    @profile.reload
    result = Completion::SaveProfile.new(@profile).call

    assert result.success?
  end

  test "save_profile respects WEBHOOK_URL environment variable" do
    original_webhook_url = ENV["WEBHOOK_URL"]

    ENV["WEBHOOK_URL"] = nil
    result = Completion::SaveProfile.new(@profile).call
    assert result.success?

    ENV["WEBHOOK_URL"] = "https://example.com/webhook"
    profile2 = build_valid_profile
    result = Completion::SaveProfile.new(profile2).call
    assert result.success?

    ENV["WEBHOOK_URL"] = original_webhook_url
  end

  private

  def build_valid_profile
    profile = CandidateProfile.new(
      first_name: "John",
      last_name: "Doe",
      email: "john.doe@example.com",
      phone: "+31612345678",
      city: "Amsterdam",
      country: "Netherlands",
      job_function: job_functions(:general_dentist),
      search_status: :active,
      available_from: 1.week.from_now,
      years_experience: 5,
      max_travel_time: 30,
      working_days: %w[monday tuesday wednesday thursday friday],
      desired_salary: 2500
    )
    profile.candidate_regions.build(region: regions(:amsterdam))
    profile.candidate_languages.build(language: languages(:dutch), level: :native)
    profile.candidate_employment_types.build(employment_type: employment_types(:employed))
    profile.save!
    profile
  end
end
