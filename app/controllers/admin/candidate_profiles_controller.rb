module Admin
  class CandidateProfilesController < BaseController
    def index
      @profiles = CandidateProfile.profile_completed
                                  .includes(:job_function)
                                  .order(completed_at: :desc)
                                  .limit(200)
    end

    def show
      @profile = CandidateProfile.find(params[:id])
    end

    def download_cv
      profile = CandidateProfile.find(params[:id])
      document = profile.latest_cv_document
      return head :not_found unless document&.file&.attached?

      send_data document.file.download,
                filename: document.original_filename || "cv",
                type: document.content_type || "application/octet-stream",
                disposition: "attachment"
    end
  end
end
