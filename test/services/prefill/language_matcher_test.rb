require "test_helper"

class Prefill::LanguageMatcherTest < ActiveSupport::TestCase
  fixtures :languages

  test "matches Dutch" do
    result = Prefill::LanguageMatcher.match_language("Dutch")
    assert_equal languages(:dutch), result
  end

  test "matches English" do
    result = Prefill::LanguageMatcher.match_language("English")
    assert_equal languages(:english), result
  end

  test "matches Dutch in Dutch" do
    result = Prefill::LanguageMatcher.match_language("Nederlands")
    assert_equal languages(:dutch), result
  end

  test "case insensitive matching" do
    result = Prefill::LanguageMatcher.match_language("DUTCH")
    assert_equal languages(:dutch), result
  end

  test "returns nil for unknown language" do
    result = Prefill::LanguageMatcher.match_language("Klingon")
    assert_nil result
  end

  test "handles nil language name" do
    result = Prefill::LanguageMatcher.match_language(nil)
    assert_nil result
  end

  test "normalize_level returns CEFR level" do
    assert_equal "A1", Prefill::LanguageMatcher.normalize_level("A1")
    assert_equal "native", Prefill::LanguageMatcher.normalize_level("native")
    assert_equal "fluent", Prefill::LanguageMatcher.normalize_level("fluent")
  end

  test "normalize_level is case-insensitive" do
    assert_equal "A1", Prefill::LanguageMatcher.normalize_level("a1")
    assert_equal "native", Prefill::LanguageMatcher.normalize_level("Native")
  end

  test "normalize_level returns nil for unknown level" do
    assert_nil Prefill::LanguageMatcher.normalize_level("unknown_level")
  end

  test "strips whitespace from language names" do
    result = Prefill::LanguageMatcher.match_language("  Dutch  ")
    assert_equal languages(:dutch), result
  end
end
