module Prefill
  class LanguageMatcher
    NAME_SYNONYMS = {
      "nederlands" => "nl", "dutch" => "nl", "nl" => "nl",
      "engels" => "en", "english" => "en", "en" => "en",
      "duits" => "de", "german" => "de", "deutsch" => "de", "de" => "de",
      "frans" => "fr", "french" => "fr", "français" => "fr", "fr" => "fr",
      "spaans" => "es", "spanish" => "es", "español" => "es", "es" => "es"
    }.freeze

    LEVEL_SYNONYMS = {
      "moedertaal" => "native", "native" => "native",
      "vloeiend" => "fluent", "fluent" => "fluent"
    }.freeze

    def self.match_language(name)
      code = NAME_SYNONYMS[name.to_s.downcase.strip]
      code && Language.find_by(code: code)
    end

    def self.normalize_level(level)
      return nil if level.blank?

      normalized = level.to_s.strip
      return LEVEL_SYNONYMS[normalized.downcase] if LEVEL_SYNONYMS.key?(normalized.downcase)
      return normalized.upcase if CandidateProfile::LANGUAGE_LEVELS.include?(normalized.upcase)

      nil
    end
  end
end
