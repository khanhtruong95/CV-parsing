class ParseCandidateCvJob < ApplicationJob
  queue_as :default

  retry_on CvParsing::RetryableApiError, Timeout::Error,
           wait: :polynomially_longer, attempts: 3 do |job, _error|
    CandidateDocument.find_by(id: job.arguments.first)
                     &.update(parsing_status: :failed, failure_reason: "Analysis service unavailable")
  end

  discard_on CvExtraction::Unsupported, CvParsing::EmptyContent, CvParsing::NonRetryableApiError do |job, error|
    CandidateDocument.find_by(id: job.arguments.first)
                     &.update(parsing_status: :failed, failure_reason: error.message)
  end

  def perform(candidate_document_id, use_mock: false)
    document = CandidateDocument.find_by(id: candidate_document_id)
    return if document.nil? || document.completed? || document.failed?

    document.processing!

    extracted = CvExtraction::Extractor.call(document)
    client = use_mock ? CvParsing::MockClient.new : CvParsing.client
    result = client.extract(extracted)

    # the stuck-guard may have failed this doc while we were parsing
    document.reload
    return if document.failed?

    PrefillService.new(document.candidate_profile, result).call

    document.update!(parsed_data: {}, parsed_at: Time.current, parsing_status: :completed)
  end
end
