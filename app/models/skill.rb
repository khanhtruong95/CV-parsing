class Skill < ApplicationRecord
  belongs_to :job_function

  scope :ordered, -> { order(:position, :name) }

  validates :name, presence: true
end
