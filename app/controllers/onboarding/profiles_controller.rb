module Onboarding
  class ProfilesController < BaseController
    before_action :require_candidate_profile!
    before_action :guard_in_flight_prefill

    def edit
      @profile = current_candidate_profile
      build_blank_repeater_rows
    end

    def update
      @profile = current_candidate_profile
      attrs = profile_params
      join_ids = attrs.extract!(:region_ids, :employment_type_ids, :skill_ids)
      begin
        @profile.assign_attributes(attrs)
      rescue ArgumentError
        @profile.errors.add(:base, "One of the selected options is not valid.")
        build_blank_repeater_rows
        return render :edit, status: :unprocessable_entity
      end

      result = Completion::SaveProfile.new(@profile, join_ids: join_ids).call
      if result.success?
        session.delete(:candidate_profile_id)
        session[:completed_profile_id] = @profile.id
        redirect_to onboarding_complete_path
      else
        build_blank_repeater_rows
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def guard_in_flight_prefill
      document = current_candidate_profile&.latest_cv_document
      redirect_to onboarding_cv_upload_path if document&.pending? || document&.processing?
    end

    def build_blank_repeater_rows
      @profile.educations.build if @profile.educations.empty?
      @profile.work_experiences.build if @profile.work_experiences.empty?
      @profile.candidate_languages.build if @profile.candidate_languages.empty?
    end

    def profile_params
      params.require(:candidate_profile).permit(
        :first_name, :last_name, :email, :phone, :city, :country,
        :job_function_id, :max_travel_time, :search_status, :reason_for_looking,
        :desired_salary, :desired_percentage, :average_daily_revenue,
        :big_status, :big_number, :years_experience, :available_from, :notice_period,
        :professional_summary, :motivation, :internal_notes, :suggested_skills,
        transport_modes: [], working_days: [], region_ids: [], employment_type_ids: [], skill_ids: [],
        educations_attributes: [ :id, :institution, :study, :location, :level, :start_date, :end_date, :position, :_destroy ],
        work_experiences_attributes: [ :id, :job_title, :company_name, :responsibilities, :start_date, :end_date, :current_job, :position, :_destroy ],
        candidate_languages_attributes: [ :id, :language_id, :level, :_destroy ]
      )
    end
  end
end
