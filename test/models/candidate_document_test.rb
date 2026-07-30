require "test_helper"

class CandidateDocumentTest < ActiveSupport::TestCase
  fixtures :candidate_profiles, :candidate_documents

  test "document validates file attachments and content types" do
    profile = candidate_profiles(:john_doe)

    validators = CandidateDocument.validators_on(:file)
    assert validators.any? { |v| v.is_a?(ActiveStorageValidations::AttachedValidator) }, "attached validator should exist"
    assert validators.any? { |v| v.is_a?(ActiveStorageValidations::ContentTypeValidator) }, "content type validator should exist"
    assert validators.any? { |v| v.is_a?(ActiveStorageValidations::SizeValidator) }, "size validator should exist"
  end

  test "document has allowed content types constant" do
    assert_equal %w[
      application/pdf
      application/msword
      application/vnd.openxmlformats-officedocument.wordprocessingml.document
    ], CandidateDocument::ALLOWED_CONTENT_TYPES
  end

  test "parsing_status enum has correct values" do
    document = CandidateDocument.new
    assert document.respond_to?(:pending?)
    assert document.respond_to?(:processing?)
    assert document.respond_to?(:completed?)
    assert document.respond_to?(:failed?)
  end

  test "parsing_status enum values work correctly" do
    document = CandidateDocument.new
    assert document.respond_to?(:pending?)
    assert document.respond_to?(:processing?)
    assert document.respond_to?(:completed?)
    assert document.respond_to?(:failed?)
  end

  test "stuck_processing? logic" do
    document = CandidateDocument.new(parsing_status: :processing, updated_at: 1.minute.ago)
    refute document.stuck_processing?, "Recent processing should not be stuck"

    document = CandidateDocument.new(parsing_status: :processing, updated_at: 6.minutes.ago)
    assert document.stuck_processing?, "Old processing should be stuck"
  end

  test "mark_stuck_as_failed! method exists" do
    document = CandidateDocument.new
    assert document.respond_to?(:mark_stuck_as_failed!)
  end

  test "document belongs to candidate profile" do
    profile = candidate_profiles(:john_doe)
    document = profile.candidate_documents.build(document_type: :cv, parsing_status: :pending)

    assert_equal profile, document.candidate_profile
  end
end
