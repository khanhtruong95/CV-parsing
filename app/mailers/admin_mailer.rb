class AdminMailer < ApplicationMailer
  def candidate_completed(profile)
    @profile = profile
    mail(
      to: ENV.fetch("ADMIN_EMAIL", "recruitment@dentamatch.local"),
      subject: "New candidate profile: #{profile.full_name}"
    )
  end
end
