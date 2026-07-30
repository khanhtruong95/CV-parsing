[
  { code: "nl", name: "Dutch" },
  { code: "en", name: "English" },
  { code: "de", name: "German" },
  { code: "fr", name: "French" },
  { code: "es", name: "Spanish" }
].each_with_index do |attrs, i|
  language = Language.find_or_create_by!(code: attrs[:code]) { |record| record.name = attrs[:name] }
  language.update!(name: attrs[:name], position: i)
end
