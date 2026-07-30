module CandidateConditionalValidations
  extend ActiveSupport::Concern

  included do
    with_options on: :complete do
      validates :desired_salary,
                presence: true, numericality: { greater_than_or_equal_to: 0, only_integer: true },
                if: :salary_based_employment?
      validates :desired_percentage,
                presence: true,
                numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100, only_integer: true },
                if: :percentage_based_employment?
      validates :average_daily_revenue,
                presence: true, numericality: { greater_than_or_equal_to: 0, only_integer: true },
                if: :daily_revenue_required?
      validates :big_status, presence: true, if: :big_required?
      validates :big_number, presence: true, if: :big_number_required?
    end
  end

  def salary_based_employment?
    employment_types.any?(&:salary_based?)
  end

  def percentage_based_employment?
    employment_types.any?(&:percentage_based?)
  end

  def daily_revenue_required?
    job_function&.requires_daily_revenue?
  end

  def big_required?
    job_function&.requires_big?
  end

  def big_number_required?
    big_required? && big_registered?
  end
end
