SKILLS_BY_FUNCTION = {
  "general_dentist"           => [ "Endodontics", "Restorative dentistry", "Pediatric dentistry", "Surgery", "Aligners" ],
  "dental_specialist"         => [ "Endodontics", "Restorative dentistry", "Pediatric dentistry", "Surgery", "Aligners" ],
  "dental_hygienist"          => [ "Periodontology", "Prevention", "Scaling", "Patient education" ],
  "prevention_assistant"      => [ "Prevention", "Scaling", "Patient education" ],
  "paro_prevention_assistant" => [ "Periodontology", "Prevention", "Scaling", "Patient education" ],
  "orthodontic_assistant"     => [ "Chairside assistance", "Sterilization", "Orthodontics", "Prevention" ],
  "dental_assistant"          => [ "Chairside assistance", "Sterilization", "Orthodontics", "Prevention" ],
  "front_office"              => [ "Planning", "Phone handling", "Invoicing", "Patient communication" ],
  "practice_manager"          => [ "Team management", "Scheduling", "HR", "Practice operations" ],
  "dental_technician"         => [ "Prosthetics", "CAD/CAM", "Crown and bridge work" ]
}.freeze

SKILLS_BY_FUNCTION.each do |function_key, skill_names|
  job_function = JobFunction.find_by!(key: function_key)
  skill_names.each_with_index do |name, i|
    skill = job_function.skills.find_or_create_by!(name: name)
    skill.update!(position: i)
  end
end
