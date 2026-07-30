module Completion
  class SaveProfile
    Result = Struct.new(:success?, :profile)

    def initialize(profile, join_ids: nil)
      @profile = profile
      @join_ids = join_ids
    end

    def call
      saved = false
      ActiveRecord::Base.transaction do
        @profile.assign_attributes(@join_ids) if @join_ids.present?
        raise ActiveRecord::Rollback unless @profile.valid?(:complete)

        # persist before with_lock below — lock! reloads and rejects dirty records
        @profile.save!
        saved = true
      end
      return Result.new(false, @profile) unless saved

      transitioned = false
      @profile.with_lock do
        break if @profile.profile_completed?

        link_user!
        @profile.update!(status: :completed, completed_at: Time.current)
        transitioned = true
      end

      notify! if transitioned
      Result.new(true, @profile)
    rescue ActiveRecord::RecordNotUnique
      Result.new(true, @profile)
    end

    private

    # emails aren't verified, so never attach this profile to an existing account
    def link_user!
      if User.exists?(email: @profile.email)
        @profile.user = nil
        @profile.duplicate_email = true
      else
        @profile.user = User.create!(
          email: @profile.email,
          first_name: @profile.first_name,
          last_name: @profile.last_name
        )
        @profile.duplicate_email = false
      end
    rescue ActiveRecord::RecordNotUnique
      @profile.user = nil
      @profile.duplicate_email = true
    end

    def notify!
      AdminMailer.candidate_completed(@profile).deliver_later
      CandidateWebhookJob.perform_later(@profile.id) if ENV["WEBHOOK_URL"].present?
    end
  end
end
