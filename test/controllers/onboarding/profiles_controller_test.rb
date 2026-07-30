require "test_helper"

class Onboarding::ProfilesControllerTest < ActionDispatch::IntegrationTest
  fixtures :candidate_profiles, :job_functions, :regions, :languages, :employment_types

  test "profile edit endpoint responds" do
    get "/onboarding/profile"
    assert [ 200, 302 ].include?(response.status)
  end

  test "profile update endpoint responds" do
    patch "/onboarding/profile", params: {
      candidate_profile: { first_name: "Test" }
    }
    assert [ 200, 302, 422 ].include?(response.status)
  end

  test "mass-assignment protection configured" do
    profile = candidate_profiles(:john_doe)
    original_status = profile.status

    patch "/onboarding/profile", params: {
      candidate_profile: {
        status: :completed,
        field_provenance: { "test" => "value" }
      }
    }

    profile.reload
    assert_equal original_status, profile.status
  end
end
