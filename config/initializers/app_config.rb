Rails.application.configure do
  config.x.cv_max_size_mb = ENV.fetch("CV_MAX_SIZE_MB", "25").to_i
  config.x.claude_model = ENV.fetch("CLAUDE_MODEL", "claude-sonnet-5")
end
