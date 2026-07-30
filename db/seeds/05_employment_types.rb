[
  { key: "employed",      name: "Employed (loondienst)",  salary_based: true,  percentage_based: false },
  { key: "self_employed", name: "Self-employed (ZZP)",    salary_based: false, percentage_based: true },
  { key: "temporary",     name: "Temporary / locum",      salary_based: false, percentage_based: false }
].each_with_index do |attrs, i|
  employment_type = EmploymentType.find_or_create_by!(key: attrs[:key]) { |record| record.name = attrs[:name] }
  employment_type.update!(name: attrs[:name], salary_based: attrs[:salary_based],
                          percentage_based: attrs[:percentage_based], position: i)
end
