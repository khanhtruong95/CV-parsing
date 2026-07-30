require "test_helper"

class Prefill::PhoneNormalizerTest < ActiveSupport::TestCase
  test "normalizes Dutch phone number 06 to +31" do
    result = Prefill::PhoneNormalizer.call("0612345678")
    assert_equal "+31612345678", result
  end

  test "leaves international phone numbers unchanged" do
    result = Prefill::PhoneNormalizer.call("+31612345678")
    assert_equal "+31612345678", result

    result = Prefill::PhoneNormalizer.call("+1234567890")
    assert_equal "+1234567890", result
  end

  test "handles phone with spaces" do
    result = Prefill::PhoneNormalizer.call("06 1234 5678")
    assert_equal "+31612345678", result
  end

  test "handles phone with dashes" do
    result = Prefill::PhoneNormalizer.call("06-1234-5678")
    assert_equal "+31612345678", result
  end

  test "returns nil for empty phone" do
    assert_nil Prefill::PhoneNormalizer.call("")
    assert_nil Prefill::PhoneNormalizer.call(nil)
  end

  test "handles phone with parentheses" do
    result = Prefill::PhoneNormalizer.call("(06) 1234-5678")
    assert_equal "+31612345678", result
  end
end
