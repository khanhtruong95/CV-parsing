require "application_system_test_case"

class ConditionalFieldsTest < ApplicationSystemTestCase
  test "conditional fields toggle with job function and employment type" do
    visit "/onboarding/cv"
    check "consent"
    click_button "Continue manually"
    assert_text "Review your profile"

    big_target = "[data-conditional-fields-target='big']"
    revenue_target = "[data-conditional-fields-target='dailyRevenue']"
    salary_target = "[data-conditional-fields-target='salary']"
    percentage_target = "[data-conditional-fields-target='percentage']"

    assert_selector big_target, visible: :hidden
    assert_selector salary_target, visible: :hidden

    big_function = JobFunction.where(requires_big: true).order(:position).first
    select big_function.name, from: "Job function"
    assert_selector big_target, visible: :visible
    assert_selector revenue_target, visible: :visible if big_function.requires_daily_revenue?

    salary_type = EmploymentType.find_by!(salary_based: true)
    check salary_type.name, allow_label_click: true
    assert_selector salary_target, visible: :visible

    percentage_type = EmploymentType.find_by!(percentage_based: true)
    check percentage_type.name, allow_label_click: true
    assert_selector percentage_target, visible: :visible

    plain_function = JobFunction.where(requires_big: false, requires_daily_revenue: false)
                                .joins(:skills).distinct.order(:position).first
    select plain_function.name, from: "Job function"
    assert_selector big_target, visible: :hidden
    assert_selector revenue_target, visible: :hidden
    assert_selector "[data-skills-filter-target='group'][data-job-function-key='#{plain_function.key}']",
                    visible: :visible
    assert_no_selector "[data-skills-filter-target='group'][data-job-function-key='#{big_function.key}']",
                       visible: :visible
  end
end
