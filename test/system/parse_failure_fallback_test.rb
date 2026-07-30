require "application_system_test_case"

class ParseFailureFallbackTest < ApplicationSystemTestCase
  # headless chrome refuses file uploads through turbo's fetch here, so the doc
  # is seeded directly; the multipart POST itself is covered by controller tests
  test "parse failure fallback: processing view, failed card, continue manually" do
    visit "/onboarding/cv"
    check "consent"
    click_button "Continue manually"
    assert_text "Review your profile"

    profile = CandidateProfile.order(:created_at).last
    document = profile.candidate_documents.new(document_type: "cv", parsing_status: :pending,
                                               original_filename: "sample-cv.pdf")
    document.file.attach(io: File.open(Rails.root.join("test/fixtures/files/sample-cv.pdf")),
                         filename: "sample-cv.pdf", content_type: "application/pdf")
    document.save!

    visit "/onboarding/cv"
    assert_text "Analyzing your CV"

    document.update!(parsing_status: :failed, failure_reason: "test")
    assert_text "We couldn't read your CV", wait: 8

    click_button "Continue manually"
    assert_current_path "/onboarding/profile"
    assert_text "Review your profile"
  end
end
