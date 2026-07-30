require "test_helper"

class WorkExperienceTest < ActiveSupport::TestCase
  fixtures :candidate_profiles, :work_experiences

  test "work experience requires job_title and company_name" do
    profile = candidate_profiles(:john_doe)
    experience = WorkExperience.new(candidate_profile: profile)
    refute experience.valid?
    assert_includes experience.errors[:job_title], I18n.t("errors.messages.blank")
    assert_includes experience.errors[:company_name], I18n.t("errors.messages.blank")
  end

  test "work experience can be created with required fields" do
    profile = candidate_profiles(:john_doe)
    experience = WorkExperience.new(
      candidate_profile: profile,
      job_title: "Senior Dentist",
      company_name: "Smile Clinic",
      start_date: Date.new(2018, 1, 1)
    )
    assert experience.valid?, experience.errors.full_messages.join("; ")
  end

  test "current_job true clears end_date" do
    profile = candidate_profiles(:john_doe)
    experience = WorkExperience.create!(
      candidate_profile: profile,
      job_title: "Senior Dentist",
      company_name: "Smile Clinic",
      start_date: Date.new(2018, 1, 1),
      end_date: Date.new(2023, 12, 31),
      current_job: false
    )

    assert_equal Date.new(2023, 12, 31), experience.end_date

    experience.update!(current_job: true)
    assert_nil experience.end_date, "current_job=true should clear end_date"
  end

  test "current_job false can have end_date" do
    profile = candidate_profiles(:john_doe)
    experience = WorkExperience.create!(
      candidate_profile: profile,
      job_title: "Senior Dentist",
      company_name: "Smile Clinic",
      start_date: Date.new(2018, 1, 1),
      current_job: false
    )

    assert_nil experience.end_date
    experience.update!(end_date: Date.new(2023, 12, 31))
    assert_equal Date.new(2023, 12, 31), experience.end_date
  end

  test "work experience belongs to candidate profile" do
    profile = candidate_profiles(:john_doe)
    experience = WorkExperience.create!(
      candidate_profile: profile,
      job_title: "Dentist",
      company_name: "Clinic"
    )
    assert_equal profile, experience.candidate_profile
  end

  test "nested attributes reject if all blank" do
    profile = candidate_profiles(:john_doe)
    assert_no_difference "WorkExperience.count" do
      profile.update!(
        work_experiences_attributes: [
          { job_title: "", company_name: "" }
        ]
      )
    end
  end

  test "can add and remove work experiences via nested attributes" do
    profile = candidate_profiles(:john_doe)
    assert_difference "WorkExperience.count", 1 do
      profile.update!(
        work_experiences_attributes: [
          { job_title: "Dentist", company_name: "Clinic" }
        ]
      )
    end

    exp_id = profile.work_experiences.last.id
    assert_difference "WorkExperience.count", -1 do
      profile.update!(
        work_experiences_attributes: [
          { id: exp_id, _destroy: true }
        ]
      )
    end
  end
end
