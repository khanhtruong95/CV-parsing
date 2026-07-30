require "test_helper"

class Prefill::JobFunctionMatcherTest < ActiveSupport::TestCase
  fixtures :job_functions

  test "matches tandarts (dentist) to general_dentist" do
    result = Prefill::JobFunctionMatcher.call("tandarts", nil)
    assert_equal job_functions(:general_dentist), result
  end

  test "matches dental hygienist variants" do
    result = Prefill::JobFunctionMatcher.call("mondhygiënist", nil)
    assert_equal job_functions(:dental_hygienist), result
  end

  test "matches prevention assistant" do
    result = Prefill::JobFunctionMatcher.call("preventieassistent", nil)
    assert_equal job_functions(:prevention_assistant), result
  end

  test "does not match prevention assistant to dental assistant" do
    result = Prefill::JobFunctionMatcher.call("preventieassistent", nil)
    refute_equal job_functions(:dental_assistant), result
  end

  test "returns nil for unknown function" do
    result = Prefill::JobFunctionMatcher.call("unknown_function", nil)
    assert_nil result
  end

  test "matches with fallback to job title if function null" do
    result = Prefill::JobFunctionMatcher.call(nil, "General Dentist")
    assert_equal job_functions(:general_dentist), result
  end

  test "prefers function_name over job title" do
    result = Prefill::JobFunctionMatcher.call("tandarts", "Some other title")
    assert_equal job_functions(:general_dentist), result
  end

  test "case insensitive matching" do
    result = Prefill::JobFunctionMatcher.call("TANDARTS", nil)
    assert_equal job_functions(:general_dentist), result

    result = Prefill::JobFunctionMatcher.call("Tandarts", nil)
    assert_equal job_functions(:general_dentist), result
  end

  test "handles empty strings as nil" do
    result = Prefill::JobFunctionMatcher.call("", "")
    assert_nil result
  end
end
