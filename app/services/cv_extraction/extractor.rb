module CvExtraction
  class Extractor
    TIMEOUT_SECONDS = 20
    MAX_TEXT_CHARS = 200_000

    def self.call(document)
      Timeout.timeout(TIMEOUT_SECONDS) do
        case document.file.blob.content_type
        when "application/pdf"
          PdfAdapter.call(document)
        when "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
          DocxAdapter.call(document)
        when "application/msword"
          DocAdapter.call(document)
        else
          raise Unsupported, "Unsupported file type"
        end
      end
    rescue Timeout::Error
      raise Unsupported, "CV took too long to read"
    end
  end
end
