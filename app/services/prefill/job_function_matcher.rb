module Prefill
  class JobFunctionMatcher
    SYNONYMS = {
      "paro-preventieassistent" => "paro_prevention_assistant",
      "paro preventie" => "paro_prevention_assistant",
      "preventieassistent" => "prevention_assistant",
      "preventie assistent" => "prevention_assistant",
      "prevention assistant" => "prevention_assistant",
      "orthodontie assistent" => "orthodontic_assistant",
      "orthodontic assistant" => "orthodontic_assistant",
      "mondhygiënist" => "dental_hygienist",
      "mondhygienist" => "dental_hygienist",
      "dental hygienist" => "dental_hygienist",
      "hygienist" => "dental_hygienist",
      "tandartsassistent" => "dental_assistant",
      "dental assistant" => "dental_assistant",
      "assistent" => "dental_assistant",
      "tandtechnicus" => "dental_technician",
      "dental technician" => "dental_technician",
      "technician" => "dental_technician",
      "praktijkmanager" => "practice_manager",
      "practice manager" => "practice_manager",
      "receptionist" => "front_office",
      "receptie" => "front_office",
      "front office" => "front_office",
      "front-office" => "front_office",
      "orthodontist" => "dental_specialist",
      "specialist" => "dental_specialist",
      "tandarts" => "general_dentist",
      "dentist" => "general_dentist"
    }.freeze

    def self.call(*candidates)
      candidates.compact.each do |raw|
        normalized = raw.to_s.downcase.strip
        next if normalized.blank?

        exact = JobFunction.find_by(key: normalized) ||
                JobFunction.where("LOWER(name) = ?", normalized).first
        return exact if exact

        SYNONYMS.each do |synonym, key|
          return JobFunction.find_by(key: key) if normalized.include?(synonym)
        end
      end
      nil
    end
  end
end
