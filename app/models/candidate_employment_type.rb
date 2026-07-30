class CandidateEmploymentType < ApplicationRecord
  belongs_to :candidate_profile
  belongs_to :employment_type
end
