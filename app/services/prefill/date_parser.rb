module Prefill
  class DateParser
    MONTHS = {
      "januari" => 1, "january" => 1, "jan" => 1,
      "februari" => 2, "february" => 2, "feb" => 2,
      "maart" => 3, "march" => 3, "mrt" => 3, "mar" => 3,
      "april" => 4, "apr" => 4,
      "mei" => 5, "may" => 5,
      "juni" => 6, "june" => 6, "jun" => 6,
      "juli" => 7, "july" => 7, "jul" => 7,
      "augustus" => 8, "august" => 8, "aug" => 8,
      "september" => 9, "sep" => 9, "sept" => 9,
      "oktober" => 10, "october" => 10, "okt" => 10, "oct" => 10,
      "november" => 11, "nov" => 11,
      "december" => 12, "dec" => 12
    }.freeze

    def self.call(value)
      raw = value.to_s.strip
      return nil if raw.blank?

      case raw
      when /\A(\d{4})-(\d{1,2})-(\d{1,2})\z/ then safe_date($1.to_i, $2.to_i, $3.to_i)
      when /\A(\d{4})-(\d{1,2})\z/           then safe_date($1.to_i, $2.to_i)
      when /\A(\d{1,2})[\/\-](\d{4})\z/      then safe_date($2.to_i, $1.to_i)
      when /\A(\d{4})\z/                     then safe_date($1.to_i, 1)
      when /\A([[:alpha:]]+)\.?\s+(\d{4})\z/i
        month = MONTHS[$1.downcase]
        month ? safe_date($2.to_i, month) : nil
      end
    end

    def self.safe_date(year, month, day = 1)
      return nil unless (1..12).cover?(month) && (1900..2100).cover?(year)

      Date.new(year, month, day)
    rescue Date::Error
      nil
    end
  end
end
