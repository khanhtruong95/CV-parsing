class JobFunction < ApplicationRecord
  has_many :skills, dependent: :destroy

  scope :ordered, -> { order(:position, :name) }

  validates :name, :key, presence: true
end
