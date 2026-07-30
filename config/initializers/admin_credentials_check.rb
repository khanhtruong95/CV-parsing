if Rails.env.production?
  password = ENV["ADMIN_PASSWORD"].to_s
  if password.empty? || password == "change-me" || password.length < 12
    raise "ADMIN_PASSWORD must be set to a strong value (12+ chars, not a placeholder) in production"
  end
end
