require "application_system_test_case"

class OnboardingManualPathTest < ApplicationSystemTestCase
  test "manual happy path: skip upload, fill form, add/remove nested rows, save" do
    visit "/onboarding/cv"
    check "consent"
    click_button "Continue manually"

    assert_current_path "/onboarding/profile"
    assert_text "Review your profile"

    fill_in "First name", with: "John"
    fill_in "Last name", with: "Doe"
    fill_in "Email", with: "john.doe@example.com"
    fill_in "Phone", with: "+31612345678"
    fill_in "City", with: "Amsterdam", match: :first
    first("select[name*='language_id']").select(Language.order(:position).first.name)

    plain_function = JobFunction.where(requires_big: false, requires_daily_revenue: false).first
    select plain_function.name, from: "Job function"
    fill_in "Max travel time (minutes)", with: "30"
    check Region.order(:position).first.name, allow_label_click: true
    select "Active", from: "Search status"

    employment = EmploymentType.where(salary_based: false, percentage_based: false).first || EmploymentType.first
    check employment.name, allow_label_click: true
    fill_in "Desired gross monthly salary (€)", with: "3000" if employment.salary_based?
    fill_in "Desired percentage of revenue (%)", with: "40" if employment.percentage_based?
    fill_in "Years of experience", with: "5"

    education_rows = "input[name*='educations_attributes'][name*='[study]']"
    assert_selector education_rows, count: 1
    click_button "+ Add education"
    assert_selector education_rows, count: 2
    last_education_study = all("input[name*='educations_attributes'][name*='[study]']").last
    within(last_education_study.ancestor("[data-nested-form-row]")) do
      click_button "Remove"
    end
    assert_selector education_rows, count: 1
    fill_in "Study", with: "Dental Assisting", match: :first

    fill_in "Job title", with: "Receptionist", match: :first
    fill_in "Company / practice", with: "Smile Clinic", match: :first
    check "This is my current job", match: :first, allow_label_click: true
    assert_selector "input[data-role='end-date'][disabled]", visible: :all

    check "Monday", allow_label_click: true
    page.execute_script(
      "const el = document.querySelector(\"input[name*='available_from']\");" \
      "el.value = '#{2.weeks.from_now.to_date.iso8601}';"
    )

    click_button "Save profile"

    assert_current_path "/onboarding/complete"
    assert_text "Thank you"
  end
end
