class CandidateProfile < ApplicationRecord
  include CandidateConditionalValidations

  WORKING_DAYS = %w[monday tuesday wednesday thursday friday saturday sunday].freeze
  TRANSPORT_MODES = %w[bike scooter public_transport car].freeze
  LANGUAGE_LEVELS = %w[A1 A2 B1 B2 C1 C2 fluent native].freeze

  belongs_to :user, optional: true
  belongs_to :job_function, optional: true

  has_many :candidate_documents, dependent: :destroy
  has_many :educations, dependent: :destroy
  has_many :work_experiences, dependent: :destroy
  has_many :candidate_skills, dependent: :destroy
  has_many :skills, through: :candidate_skills
  has_many :candidate_languages, dependent: :destroy
  has_many :languages, through: :candidate_languages
  has_many :candidate_regions, dependent: :destroy
  has_many :regions, through: :candidate_regions
  has_many :candidate_employment_types, dependent: :destroy
  has_many :employment_types, through: :candidate_employment_types

  accepts_nested_attributes_for :educations, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :work_experiences, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :candidate_languages, allow_destroy: true,
                                reject_if: ->(attrs) { attrs[:language_id].blank? }

  # checkbox groups post a hidden "" entry
  before_validation do
    self.working_days = Array(working_days).compact_blank
    self.transport_modes = Array(transport_modes).compact_blank
  end

  enum :search_status, { active: 0, passive: 1, inactive: 2 }
  enum :big_status, { registered: 0, in_progress: 1, under_supervision: 2, not_applicable: 3 }, prefix: :big
  enum :status, { in_progress: 0, completed: 1 }, prefix: :profile

  with_options on: :complete do
    validates :first_name, :last_name, :city, :job_function_id, :search_status, :available_from, presence: true
    validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
    validates :phone, presence: true, phone: true
    validates :max_travel_time, :years_experience,
              presence: true, numericality: { greater_than_or_equal_to: 0, only_integer: true }
    validate :at_least_one_region
    validate :at_least_one_language
    validate :at_least_one_employment_type
    validate :at_least_one_working_day
    validate :working_days_are_known
    validate :transport_modes_are_known
  end

  def self.purge_stale!(older_than: 30.days.ago)
    profile_in_progress.where(updated_at: ...older_than).destroy_all.size
  end

  def full_name = [ first_name, last_name ].compact_blank.join(" ")

  def provenance_for(field) = field_provenance[field.to_s] || {}
  def prefilled? = prefilled_at.present?

  def latest_cv_document
    candidate_documents.where(document_type: "cv").order(:created_at).last
  end

  private

  def at_least_one_region
    errors.add(:regions, :blank, message: "must include at least one region") if candidate_regions.empty?
  end

  def at_least_one_language
    errors.add(:languages, :blank, message: "must include at least one language") if candidate_languages.reject(&:marked_for_destruction?).empty?
  end

  def at_least_one_employment_type
    errors.add(:employment_types, :blank, message: "must include at least one employment type") if candidate_employment_types.empty?
  end

  def at_least_one_working_day
    errors.add(:working_days, :blank, message: "must include at least one working day") if working_days.blank?
  end

  def working_days_are_known
    errors.add(:working_days, :inclusion, message: "contains an unknown day") if (working_days - WORKING_DAYS).any?
  end

  def transport_modes_are_known
    errors.add(:transport_modes, :inclusion, message: "contains an unknown option") if (transport_modes - TRANSPORT_MODES).any?
  end
end
