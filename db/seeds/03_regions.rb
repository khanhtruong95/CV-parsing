%w[
  Groningen Friesland Drenthe Overijssel Flevoland Gelderland
  Utrecht Noord-Holland Zuid-Holland Zeeland Noord-Brabant Limburg
].each_with_index do |name, i|
  region = Region.find_or_create_by!(name: name)
  region.update!(position: i)
end
