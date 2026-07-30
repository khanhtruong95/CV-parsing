require "test_helper"

class Onboarding::CvUploadsControllerTest < ActionDispatch::IntegrationTest
  fixtures :candidate_profiles

  test "cv show endpoint returns 200" do
    get "/onboarding/cv"
    assert_response :success
  end

  test "cv create validates consent" do
    post "/onboarding/cv", params: {
      candidate_document: {
        file: fixture_file_upload("sample-cv.pdf", "application/pdf")
      }
    }
    assert [ 422, 302 ].include?(response.status)
  end

  test "cv skip requires consent" do
    post "/onboarding/cv/skip"
    assert [ 200, 302, 422 ].include?(response.status)
  end

  test "file validations are in place" do
    assert CandidateDocument.validators_on(:file).any? { |v| v.is_a?(ActiveStorageValidations::AttachedValidator) }
  end

  test "cv status endpoint exists" do
    get "/onboarding/cv/status", params: { candidate_document_id: 1 }
    assert [ 200, 302 ].include?(response.status)
  end

  test "demo seeds a sample CV and enqueues a mock parse" do
    post onboarding_cv_demo_path, params: { consent: "1" }
    assert_redirected_to onboarding_cv_upload_path
    document = CandidateDocument.order(:created_at).last
    assert document.file.attached?
    assert_equal "sample-cv.pdf", document.original_filename
    assert_enqueued_with(job: ParseCandidateCvJob, args: [ document.id, { use_mock: true } ])
  end

  test "demo without consent is rejected" do
    assert_no_difference "CandidateProfile.count" do
      post onboarding_cv_demo_path
    end
    assert_response :unprocessable_entity
  end
end
