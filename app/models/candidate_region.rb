class CandidateRegion < ApplicationRecord
  belongs_to :candidate_profile
  belongs_to :region
end
