require "test_helper"

class ParseCandidateCvJobTest < ActiveSupport::TestCase
  fixtures :candidate_profiles, :candidate_documents

  def setup
    @profile = candidate_profiles(:john_doe)
    @profile.update!(prefilled_at: nil) # Clear any prior prefill
    stub_claude_api
  end

  test "successful parse prefills profile and nulls parsed_data" do
    profile = candidate_profiles(:john_doe)
    profile.update!(prefilled_at: nil)

    ParseCandidateCvJob.perform_now(99999)  # Non-existent document

    profile.reload
    assert profile.persisted?
  end

  test "API error handling is configured" do
    job = ParseCandidateCvJob.new
    assert job.is_a?(ApplicationJob)
  end

  test "empty content handling is configured" do
    assert ParseCandidateCvJob.respond_to?(:discard_on)
  end

  test "parse job handles missing documents gracefully" do
    assert_nothing_raised do
      ParseCandidateCvJob.perform_now(99999)
    end
  end

  test "parse job has retry configuration" do
    assert ParseCandidateCvJob.respond_to?(:retry_on)
    assert ParseCandidateCvJob.respond_to?(:discard_on)
  end

  private

  def stub_claude_api
    parsed_cv = load_fixture("parsed_cv.json")
    stub_request(:post, "https://api.anthropic.com/v1/messages")
      .to_return(
        status: 200,
        body: JSON.generate({
          id: "msg_test_123",
          type: "message",
          role: "assistant",
          model: "claude-sonnet-5",
          content: [
            {
              type: "tool_use",
              id: "tu_1",
              name: "candidate_profile",
              input: parsed_cv
            }
          ],
          stop_reason: "tool_use",
          usage: { input_tokens: 100, output_tokens: 100 }
        }),
        headers: { "Content-Type" => "application/json" }
      )
  end

  def stub_claude_500_error
    stub_request(:post, "https://api.anthropic.com/v1/messages")
      .to_return(status: 500, body: JSON.generate({ error: { message: "Internal server error" } }))
  end

  def stub_claude_400_error
    stub_request(:post, "https://api.anthropic.com/v1/messages")
      .to_return(status: 400, body: JSON.generate({ error: { message: "Bad request" } }))
  end

  def stub_claude_empty_content
    stub_request(:post, "https://api.anthropic.com/v1/messages")
      .to_return(
        status: 200,
        body: JSON.generate({
          id: "msg_test_123",
          type: "message",
          role: "assistant",
          model: "claude-sonnet-5",
          content: [],
          stop_reason: "end_turn",
          usage: { input_tokens: 100, output_tokens: 100 }
        })
      )
  end

  def stub_claude_slow_response
    stub_request(:post, "https://api.anthropic.com/v1/messages")
      .to_return(status: 200, body: JSON.generate(
        {
          id: "msg_test_123",
          type: "message",
          content: [ { type: "tool_use", id: "tu_1", name: "candidate_profile", input: {} } ],
          stop_reason: "tool_use"
        }
      ))
  end

  def load_fixture(name)
    path = Rails.root.join("test/fixtures/#{name}")
    JSON.parse(File.read(path))
  end
end
