class WorkExperience < ApplicationRecord
  belongs_to :candidate_profile

  scope :ordered, -> { order(:position, :id) }

  validates :job_title, :company_name, presence: true

  before_validation { self.end_date = nil if current_job }
end
