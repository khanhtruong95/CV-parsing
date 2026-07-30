class CandidateDocument < ApplicationRecord
  ALLOWED_CONTENT_TYPES = %w[
    application/pdf
    application/msword
    application/vnd.openxmlformats-officedocument.wordprocessingml.document
  ].freeze

  belongs_to :candidate_profile
  has_one_attached :file

  enum :parsing_status, { pending: 0, processing: 1, completed: 2, failed: 3 }

  validates :file,
            attached: true,
            content_type: { in: ALLOWED_CONTENT_TYPES, spoofing_protection: true },
            size: { less_than: ->(_record) { Rails.application.config.x.cv_max_size_mb.megabytes } }

  STUCK_PROCESSING_AFTER = 3.minutes

  def stuck_processing?
    processing? && updated_at < STUCK_PROCESSING_AFTER.ago
  end

  def mark_stuck_as_failed!
    update!(parsing_status: :failed, failure_reason: "timed_out") if stuck_processing?
  end
end
