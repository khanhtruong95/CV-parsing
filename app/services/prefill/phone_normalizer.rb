module Prefill
  class PhoneNormalizer
    def self.call(value)
      return nil if value.blank?

      parsed = Phonelib.parse(value)
      parsed.valid? ? parsed.e164 : value.to_s.strip
    end
  end
end
