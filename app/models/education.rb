class Education < ApplicationRecord
  LEVELS = %w[MBO HBO Bachelor Master Doctor Course].freeze

  belongs_to :candidate_profile

  scope :ordered, -> { order(:position, :id) }

  validates :study, presence: true
end
