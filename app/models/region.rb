class Region < ApplicationRecord
  scope :ordered, -> { order(:position, :name) }

  validates :name, presence: true
end
