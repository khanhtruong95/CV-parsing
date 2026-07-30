module ProvenanceBadgeHelper
  ASSOCIATION_PRESENCE = {
    "languages" => ->(profile) {
      profile.candidate_languages.reject { |cl| cl.marked_for_destruction? || cl.language_id.blank? }.any?
    },
    "regions" => ->(profile) { profile.regions.any? },
    "employment_types" => ->(profile) { profile.employment_types.any? },
    "skills" => ->(profile) { profile.skills.any? },
    "educations" => ->(profile) {
      profile.educations.reject { |e| e.marked_for_destruction? || e.study.blank? }.any?
    },
    "work_experiences" => ->(profile) {
      profile.work_experiences.reject { |w| w.marked_for_destruction? || w.job_title.blank? }.any?
    },
    "working_days" => ->(profile) { profile.working_days.present? }
  }.freeze

  def field_state(profile, field, required: false)
    field = field.to_s
    provenance = profile.field_provenance[field]

    if provenance && provenance["source"] == "cv"
      %w[low medium].include?(provenance["confidence"]) ? :check : :cv
    elsif required && !field_value_present?(profile, field)
      :missing
    else
      :none
    end
  end

  def provenance_badge(profile, field, required: false)
    render "onboarding/shared/badge", state: field_state(profile, field, required: required)
  end

  def input_state_class(profile, field, required: false)
    case field_state(profile, field, required: required)
    when :check then "input-warning"
    when :missing then "input-missing"
    end
  end

  def provenance_summary(profile)
    extracted = 0
    check = 0
    profile.field_provenance.each_value do |provenance|
      case provenance["confidence"]
      when "high" then extracted += 1
      when "low", "medium" then check += 1
      end
    end
    missing = required_field_names(profile).count { |field| field_state(profile, field, required: true) == :missing }
    { extracted: extracted, check: check, missing: missing }
  end

  private

  def field_value_present?(profile, field)
    presence_check = ASSOCIATION_PRESENCE[field]
    return presence_check.call(profile) if presence_check
    return false unless profile.respond_to?(field)

    profile.public_send(field).present?
  end

  def required_field_names(profile)
    fields = %w[first_name last_name email phone city job_function_id max_travel_time
                regions search_status employment_types years_experience working_days available_from]
    fields << "big_status" if profile.big_required?
    fields << "big_number" if profile.big_number_required?
    fields << "desired_salary" if profile.salary_based_employment?
    fields << "desired_percentage" if profile.percentage_based_employment?
    fields << "average_daily_revenue" if profile.daily_revenue_required?
    fields
  end
end
