module Onboarding
  class CvUploadsController < BaseController
    def new
      @document = current_candidate_profile&.latest_cv_document
      @state =
        if params[:retry].present? then :upload
        elsif @document&.completed? then :completed
        elsif @document&.pending? || @document&.processing? then :processing
        elsif @document&.failed? then :failed
        else :upload
        end

      redirect_to onboarding_profile_path if @state == :completed
    end

    def create
      return reject_upload("Please accept the consent statement to continue.") unless consent_given?
      return reject_upload("Please choose a CV file to upload.") if params[:file].blank?

      if current_candidate_profile&.latest_cv_document&.then { |d| d.pending? || d.processing? }
        return redirect_to onboarding_cv_upload_path
      end

      profile = current_candidate_profile || CandidateProfile.new
      document = nil
      ActiveRecord::Base.transaction do
        profile.consent_accepted_at ||= Time.current
        profile.save!
        document = build_cv_document(profile)
        raise ActiveRecord::Rollback unless document.save
      end

      if document&.persisted?
        session[:candidate_profile_id] = profile.id
        ParseCandidateCvJob.perform_later(document.id)
        redirect_to onboarding_cv_upload_path
      else
        reject_upload(document.errors.full_messages.to_sentence)
      end
    end

    def status
      return if require_candidate_profile!

      @document = current_candidate_profile.latest_cv_document
      @document&.mark_stuck_as_failed!
      render layout: false
    end
    def demo
      return head :not_found if Rails.env.production?

      unless consent_given? || current_candidate_profile&.consent_accepted_at.present?
        return reject_upload("Please accept the consent statement to continue.")
      end
      if current_candidate_profile&.latest_cv_document&.then { |d| d.pending? || d.processing? }
        return redirect_to onboarding_cv_upload_path
      end

      profile = current_candidate_profile || CandidateProfile.new
      profile.consent_accepted_at ||= Time.current
      profile.save!
      session[:candidate_profile_id] = profile.id

      document = profile.candidate_documents.new(document_type: "cv", parsing_status: :pending)
      document.file.attach(io: File.open(Rails.root.join("lib/assets/sample-cv.pdf")),
                           filename: "sample-cv.pdf", content_type: "application/pdf")
      document.original_filename = "sample-cv.pdf"
      document.content_type = "application/pdf"
      document.file_size = document.file.blob.byte_size
      document.save!

      ParseCandidateCvJob.perform_later(document.id, use_mock: true)
      redirect_to onboarding_cv_upload_path
    end

    def skip
      profile = current_candidate_profile || CandidateProfile.new
      unless profile.consent_accepted_at.present? || consent_given?
        return reject_upload("Please accept the consent statement to continue.")
      end

      profile.consent_accepted_at ||= Time.current
      profile.save!
      session[:candidate_profile_id] = profile.id
      redirect_to onboarding_profile_path
    end

    private

    def consent_given?
      params[:consent] == "1"
    end

    def build_cv_document(profile)
      document = profile.candidate_documents.new(document_type: "cv", parsing_status: :pending)
      document.file.attach(params[:file])
      if document.file.attached?
        document.original_filename = document.file.filename.to_s
        document.content_type = document.file.blob.content_type
        document.file_size = document.file.blob.byte_size
      end
      document
    end

    def reject_upload(message)
      @state = :upload
      @upload_error = message
      render :new, status: :unprocessable_entity
    end
  end
end
