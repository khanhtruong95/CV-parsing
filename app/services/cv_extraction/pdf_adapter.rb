module CvExtraction
  class PdfAdapter
    def self.call(document)
      limit = [ Rails.application.config.x.cv_max_size_mb.megabytes, 30.megabytes ].min
      raise Unsupported, "PDF too large to analyze" if document.file.blob.byte_size > limit

      { kind: :pdf_bytes, payload: document.file.download }
    end
  end
end
