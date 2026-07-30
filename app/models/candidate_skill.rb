class CandidateSkill < ApplicationRecord
  belongs_to :candidate_profile
  belongs_to :skill
end
