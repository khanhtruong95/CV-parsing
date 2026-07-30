require "test_helper"

class Prefill::SkillMatcherTest < ActiveSupport::TestCase
  fixtures :skills, :job_functions

  test "matches known skill names" do
    result = Prefill::SkillMatcher.call([ "Dental diagnostics" ], job_function: nil)
    assert_equal 1, result.matched.length
    assert result.matched.first.is_a?(Skill)
  end

  test "returns unmatched skills in suggested_skills" do
    result = Prefill::SkillMatcher.call(
      [ "Dental diagnostics", "Unknown Skill" ],
      job_function: nil
    )
    assert_equal 1, result.matched.length
    assert_includes result.unmatched, "Unknown Skill"
  end

  test "returns empty matched for all unknown skills" do
    result = Prefill::SkillMatcher.call(
      [ "Unknown Skill 1", "Unknown Skill 2" ],
      job_function: nil
    )
    assert result.matched.empty?
    assert_equal 2, result.unmatched.length
  end

  test "handles empty skill list" do
    result = Prefill::SkillMatcher.call([], job_function: nil)
    assert result.matched.empty?
    assert result.unmatched.empty?
  end

  test "handles nil skill list" do
    result = Prefill::SkillMatcher.call(nil, job_function: nil)
    assert result.matched.empty?
    assert result.unmatched.empty?
  end

  test "matches skills case-insensitively" do
    result = Prefill::SkillMatcher.call([ "DENTAL DIAGNOSTICS" ], job_function: nil)
    assert_equal 1, result.matched.length
  end

  test "filters out blank/nil skills" do
    result = Prefill::SkillMatcher.call(
      [ nil, "", "Dental diagnostics" ],
      job_function: nil
    )
    assert_equal 1, result.matched.length
  end

  test "returns result struct with matched and unmatched" do
    result = Prefill::SkillMatcher.call([ "Dental diagnostics" ], job_function: nil)
    assert_respond_to result, :matched
    assert_respond_to result, :unmatched
  end
end
