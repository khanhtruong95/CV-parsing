require "test_helper"

class Onboarding::CompletionsControllerTest < ActionDispatch::IntegrationTest
  test "completions show endpoint exists" do
    get "/onboarding/complete"
    assert [ 200, 302 ].include?(response.status)
  end
end
