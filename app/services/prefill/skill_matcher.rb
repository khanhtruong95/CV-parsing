module Prefill
  class SkillMatcher
    Result = Struct.new(:matched, :unmatched)

    def self.call(names, job_function: nil)
      scope = job_function ? job_function.skills : Skill.all
      matched = []
      unmatched = []

      Array(names).map { |n| n.to_s.strip }.reject(&:blank?).uniq.each do |name|
        skill = scope.where("LOWER(name) = ?", name.downcase).first
        skill ? matched << skill : unmatched << name
      end

      Result.new(matched.uniq, unmatched)
    end
  end
end
