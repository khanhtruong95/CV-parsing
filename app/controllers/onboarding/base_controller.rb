module Onboarding
  class BaseController < ApplicationController
    helper_method :current_candidate_profile

    private

    def current_candidate_profile
      return @current_candidate_profile if defined?(@current_candidate_profile)

      @current_candidate_profile = CandidateProfile.find_by(id: session[:candidate_profile_id])
    end

    def require_candidate_profile!
      return if current_candidate_profile

      redirect_to onboarding_cv_upload_path, alert: "Your session expired — please start again."
    end
  end
end
