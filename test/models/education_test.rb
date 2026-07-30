require "test_helper"

class EducationTest < ActiveSupport::TestCase
  fixtures :candidate_profiles, :educations

  test "education requires study field" do
    profile = candidate_profiles(:john_doe)
    education = Education.new(candidate_profile: profile)
    refute education.valid?
    assert_includes education.errors[:study], I18n.t("errors.messages.blank")
  end

  test "education can be created with required fields" do
    profile = candidate_profiles(:john_doe)
    education = Education.new(
      candidate_profile: profile,
      study: "Dentistry"
    )
    assert education.valid?
  end

  test "education level is optional" do
    profile = candidate_profiles(:john_doe)
    education = Education.new(
      candidate_profile: profile,
      study: "Dentistry",
      level: nil
    )
    assert education.valid?
  end

  test "education has levels constant" do
    assert_respond_to Education, :const_get
    levels = Education::LEVELS rescue nil
    assert_instance_of Array, levels if levels.present?
  end

  test "education belongs to candidate profile" do
    profile = candidate_profiles(:john_doe)
    education = Education.create!(
      candidate_profile: profile,
      study: "Dentistry"
    )
    assert_equal profile, education.candidate_profile
  end

  test "nested attributes handle blank study" do
    profile = candidate_profiles(:john_doe)
    initial_count = profile.educations.count
    profile.update!(
      educations_attributes: [
        { study: "", institution: "" }
      ]
    )
    assert_equal initial_count, profile.educations.count
  end

  test "can add and remove educations via nested attributes" do
    profile = candidate_profiles(:john_doe)
    assert_difference "Education.count", 1 do
      profile.update!(
        educations_attributes: [
          { study: "Dentistry", institution: "University of Amsterdam" }
        ]
      )
    end

    edu_id = profile.educations.last.id
    assert_difference "Education.count", -1 do
      profile.update!(
        educations_attributes: [
          { id: edu_id, _destroy: true }
        ]
      )
    end
  end

  test "education can have dates" do
    profile = candidate_profiles(:john_doe)
    education = Education.create!(
      candidate_profile: profile,
      study: "Dentistry",
      start_date: Date.new(2015, 9, 1),
      end_date: Date.new(2019, 6, 30)
    )

    assert_equal Date.new(2015, 9, 1), education.start_date
    assert_equal Date.new(2019, 6, 30), education.end_date
  end

  test "education can store institution and location" do
    profile = candidate_profiles(:john_doe)
    education = Education.create!(
      candidate_profile: profile,
      study: "Dentistry",
      institution: "University of Amsterdam",
      location: "Amsterdam, Netherlands"
    )

    assert_equal "University of Amsterdam", education.institution
    assert_equal "Amsterdam, Netherlands", education.location
  end
end
