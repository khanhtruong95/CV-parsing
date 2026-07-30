class Rack::Attack
  throttle("onboarding/cv/ip", limit: 10, period: 1.hour) do |req|
    req.ip if req.post? && req.path.start_with?("/onboarding/cv")
  end

  throttle("onboarding/writes/ip", limit: 60, period: 1.hour) do |req|
    req.ip if (req.post? || req.patch?) && req.path.start_with?("/onboarding")
  end

  throttle("onboarding/cv/session", limit: 10, period: 1.hour) do |req|
    if req.post? && req.path.start_with?("/onboarding/cv")
      session_cookie = req.cookies.find { |name, _| name.end_with?("_session") }&.last
      Digest::SHA256.hexdigest(session_cookie) if session_cookie
    end
  end

  self.throttled_responder = lambda do |_request|
    [ 429, { "content-type" => "text/plain" }, [ "Too many requests. Please try again later.\n" ] ]
  end
end
