require "net/http"

class CandidateWebhookJob < ApplicationJob
  queue_as :default

  def perform(candidate_profile_id)
    url = ENV["WEBHOOK_URL"]
    return if url.blank?

    profile = CandidateProfile.find_by(id: candidate_profile_id)
    return unless profile&.profile_completed?

    payload = {
      event: "candidate_onboarding_completed",
      profile_id: profile.id,
      full_name: profile.full_name,
      email: profile.email,
      job_function: profile.job_function&.key,
      completed_at: profile.completed_at&.iso8601
    }

    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == "https"
    http.open_timeout = 5
    http.read_timeout = 5
    http.post(uri.request_uri.presence || "/", payload.to_json, "Content-Type" => "application/json")
  rescue StandardError => e
    Rails.logger.warn("candidate_onboarding_completed webhook failed: #{e.class} #{e.message}")
  end
end
