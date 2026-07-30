[
  { key: "general_dentist",           name: "General dentist",           requires_big: true,  requires_daily_revenue: true },
  { key: "dental_hygienist",          name: "Dental hygienist",          requires_big: true,  requires_daily_revenue: true },
  { key: "dental_specialist",         name: "Specialist",                requires_big: true,  requires_daily_revenue: true },
  { key: "prevention_assistant",      name: "Prevention assistant",      requires_big: false, requires_daily_revenue: true },
  { key: "paro_prevention_assistant", name: "Paro-prevention assistant", requires_big: false, requires_daily_revenue: false },
  { key: "orthodontic_assistant",     name: "Orthodontic assistant",     requires_big: false, requires_daily_revenue: false },
  { key: "dental_assistant",          name: "Dental assistant",          requires_big: false, requires_daily_revenue: false },
  { key: "front_office",              name: "Front-office / receptionist", requires_big: false, requires_daily_revenue: false },
  { key: "practice_manager",          name: "Practice manager",          requires_big: false, requires_daily_revenue: false },
  { key: "dental_technician",         name: "Dental technician",         requires_big: false, requires_daily_revenue: false }
].each_with_index do |attrs, i|
  jf = JobFunction.find_or_create_by!(key: attrs[:key]) do |record|
    record.name = attrs[:name]
  end
  jf.update!(name: attrs[:name], requires_big: attrs[:requires_big],
             requires_daily_revenue: attrs[:requires_daily_revenue], position: i)
end
