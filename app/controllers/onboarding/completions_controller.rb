module Onboarding
  class CompletionsController < BaseController
    def show
      @profile = CandidateProfile.profile_completed.find_by(id: session[:completed_profile_id])
      redirect_to onboarding_cv_upload_path if @profile.nil?
    end
  end
end
