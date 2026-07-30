require "test_helper"

class Prefill::DateParserTest < ActiveSupport::TestCase
  test "parses ISO format YYYY-MM" do
    result = Prefill::DateParser.call("2015-09")
    assert_equal Date.new(2015, 9, 1), result
  end

  test "parses ISO format YYYY-MM-DD" do
    result = Prefill::DateParser.call("2015-09-15")
    assert_equal Date.new(2015, 9, 15), result
  end

  test "parses Dutch month names with year" do
    result = Prefill::DateParser.call("september 2015")
    assert_equal Date.new(2015, 9, 1), result

    result = Prefill::DateParser.call("maart 2020")
    assert_equal Date.new(2020, 3, 1), result

    result = Prefill::DateParser.call("januari 2018")
    assert_equal Date.new(2018, 1, 1), result
  end

  test "parses English month names with year" do
    result = Prefill::DateParser.call("September 2015")
    assert_equal Date.new(2015, 9, 1), result

    result = Prefill::DateParser.call("March 2020")
    assert_equal Date.new(2020, 3, 1), result

    result = Prefill::DateParser.call("January 2018")
    assert_equal Date.new(2018, 1, 1), result
  end

  test "parses DD/YYYY format" do
    result = Prefill::DateParser.call("09/2015")
    assert_equal Date.new(2015, 9, 1), result
  end

  test "parses year only" do
    result = Prefill::DateParser.call("2015")
    assert_equal Date.new(2015, 1, 1), result
  end

  test "returns nil for invalid date strings" do
    assert_nil Prefill::DateParser.call("garbage")
    assert_nil Prefill::DateParser.call("invalid date")
    assert_nil Prefill::DateParser.call("")
    assert_nil Prefill::DateParser.call(nil)
  end

  test "returns nil for blank string" do
    assert_nil Prefill::DateParser.call("   ")
  end

  test "case-insensitive month parsing" do
    result = Prefill::DateParser.call("SEPTEMBER 2015")
    assert_equal Date.new(2015, 9, 1), result

    result = Prefill::DateParser.call("September 2015")
    assert_equal Date.new(2015, 9, 1), result
  end
end
