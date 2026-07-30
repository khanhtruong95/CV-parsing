require "test_helper"

class Admin::CandidateProfilesControllerTest < ActionDispatch::IntegrationTest
  fixtures :candidate_profiles

  test "admin index without auth returns 401" do
    get "/admin/candidate_profiles"
    assert_response :unauthorized
  end

  test "admin index with wrong password returns 401" do
    get "/admin/candidate_profiles", headers: {
      "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials("admin", "wrong_password")
    }
    assert_response :unauthorized
  end

  test "admin index with correct auth returns 200" do
    get "/admin/candidate_profiles", headers: {
      "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials("admin", ENV["ADMIN_PASSWORD"])
    }
    assert_response :success
  end

  test "admin routes exist" do
    get "/admin/candidate_profiles"
    assert_response :unauthorized
  end

  test "admin can view completed candidates" do
    profile = candidate_profiles(:john_doe)
    profile.update!(status: :completed, completed_at: Time.current)

    get "/admin/candidate_profiles", headers: {
      "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials("admin", ENV["ADMIN_PASSWORD"])
    }

    assert_response :success
  end
end
