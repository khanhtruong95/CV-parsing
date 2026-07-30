module CvParsing
  # In development without an API key, fall back to the mock so the full
  # flow stays demoable offline. Production always uses the real client.
  def self.client
    if ENV["ANTHROPIC_API_KEY"].present?
      ClaudeClient.new
    elsif Rails.env.development?
      MockClient.new
    else
      ClaudeClient.new
    end
  end

  class RetryableApiError < StandardError; end
  class NonRetryableApiError < StandardError; end
  class EmptyContent < StandardError; end
end
