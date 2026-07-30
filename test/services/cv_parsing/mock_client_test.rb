require "test_helper"

module CvParsing
  class MockClientTest < ActiveSupport::TestCase
    test "sample data matches the extraction schema and prefills a profile" do
      result = MockClient::SAMPLE
      assert_equal ExtractionSchema::INPUT["required"].sort, result.keys.sort

      profile = CandidateProfile.create!(consent_accepted_at: Time.current)
      PrefillService.new(profile, result).call
      profile.reload

      assert_equal "Sanne", profile.first_name
      assert profile.prefilled?
      assert profile.educations.any?
      assert profile.work_experiences.any?
    end
  end
end
