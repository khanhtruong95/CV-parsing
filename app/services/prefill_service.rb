class PrefillService
  SCALAR_FIELDS = {
    "first_name" => :first_name, "last_name" => :last_name,
    "email" => :email, "city" => :city, "country" => :country,
    "years_experience" => :years_experience, "big_number" => :big_number,
    "professional_summary" => :professional_summary
  }.freeze

  def initialize(profile, parsed)
    @profile = profile
    @parsed = parsed
    @provenance = {}
  end

  def call
    return if @profile.prefilled?

    @profile.transaction do
      assign_scalars
      assign_phone
      assign_big_status
      assign_job_function
      assign_languages
      assign_skills
      build_educations
      build_work_experiences

      @profile.field_provenance = @provenance
      @profile.prefilled_at = Time.current
      @profile.save!
    end
  end

  private

  def field(key)
    node = @parsed[key]
    return [ nil, nil ] unless node.is_a?(Hash)

    value = node["value"]
    value = nil if value.respond_to?(:blank?) && value.blank?
    [ value, node["confidence"] ]
  end

  def record_provenance(attribute, confidence)
    @provenance[attribute.to_s] = { "source" => "cv", "confidence" => confidence || "medium" }
  end

  def assign(attribute, value, confidence)
    return if value.nil?

    @profile.public_send("#{attribute}=", value)
    record_provenance(attribute, confidence)
  end

  def assign_scalars
    SCALAR_FIELDS.each do |key, attribute|
      value, confidence = field(key)
      assign(attribute, value, confidence)
    end
  end

  def assign_phone
    value, confidence = field("phone")
    assign(:phone, Prefill::PhoneNormalizer.call(value), confidence) if value
  end

  def assign_big_status
    value, confidence = field("big_status")
    assign(:big_status, value, confidence) if value && CandidateProfile.big_statuses.key?(value)
  end

  def assign_job_function
    function_name, confidence = field("dental_job_function")
    job_title, title_confidence = field("current_job_title")
    job_function = Prefill::JobFunctionMatcher.call(function_name, job_title)
    return unless job_function

    @profile.job_function = job_function
    record_provenance(:job_function_id, confidence || title_confidence)
  end

  def assign_languages
    entries = Array(@parsed["languages"])
    added = false
    entries.each do |entry|
      name, _c = value_of(entry, "name")
      language = Prefill::LanguageMatcher.match_language(name)
      next unless language
      next if @profile.candidate_languages.any? { |cl| cl.language_id == language.id }

      level, _lc = value_of(entry, "level")
      @profile.candidate_languages.build(language: language, level: Prefill::LanguageMatcher.normalize_level(level))
      added = true
    end
    record_provenance(:languages, entry_confidence(entries)) if added
  end

  def assign_skills
    names = Array(@parsed["skills"]).filter_map { |entry| value_of(entry, "name").first }
    return if names.empty?

    result = Prefill::SkillMatcher.call(names, job_function: @profile.job_function)
    result.matched.each { |skill| @profile.candidate_skills.build(skill: skill) }
    @profile.suggested_skills = result.unmatched.join("\n") if result.unmatched.any?
    record_provenance(:skills, "medium") if result.matched.any? || result.unmatched.any?
  end

  def build_educations
    added = false
    Array(@parsed["educations"]).each_with_index do |entry, index|
      study, _c = value_of(entry, "study")
      next if study.blank?

      @profile.educations.build(
        study: study,
        institution: value_of(entry, "institution").first,
        location: value_of(entry, "location").first,
        level: normalize_education_level(value_of(entry, "level").first),
        start_date: Prefill::DateParser.call(value_of(entry, "start_date").first),
        end_date: Prefill::DateParser.call(value_of(entry, "end_date").first),
        position: index
      )
      added = true
    end
    record_provenance(:educations, entry_confidence(Array(@parsed["educations"]))) if added
  end

  def build_work_experiences
    added = false
    Array(@parsed["work_experiences"]).each_with_index do |entry, index|
      job_title, _c = value_of(entry, "job_title")
      company, _cc = value_of(entry, "company_name")
      next if job_title.blank? || company.blank?

      current = value_of(entry, "current_job").first == true
      @profile.work_experiences.build(
        job_title: job_title,
        company_name: company,
        responsibilities: value_of(entry, "responsibilities").first,
        start_date: Prefill::DateParser.call(value_of(entry, "start_date").first),
        end_date: current ? nil : Prefill::DateParser.call(value_of(entry, "end_date").first),
        current_job: current,
        position: index
      )
      added = true
    end
    record_provenance(:work_experiences, entry_confidence(Array(@parsed["work_experiences"]))) if added
  end

  def value_of(entry, key)
    node = entry.is_a?(Hash) ? entry[key] : nil
    return [ nil, nil ] unless node.is_a?(Hash)

    value = node["value"]
    value = nil if value.respond_to?(:blank?) && value.blank?
    [ value, node["confidence"] ]
  end

  def entry_confidence(entries)
    confidences = entries.flat_map { |e| e.is_a?(Hash) ? e.values : [] }
                         .filter_map { |n| n.is_a?(Hash) ? n["confidence"] : nil }
    %w[low medium high].find { |c| confidences.include?(c) } || "medium"
  end

  def normalize_education_level(raw)
    return nil if raw.blank?

    Education::LEVELS.find { |level| level.casecmp?(raw.to_s.strip) }
  end
end
