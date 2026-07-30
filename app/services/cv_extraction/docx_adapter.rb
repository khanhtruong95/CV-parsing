module CvExtraction
  class DocxAdapter
    def self.call(document)
      text = Tempfile.create([ "cv", ".docx" ], binmode: true) do |tempfile|
        tempfile.write(document.file.download)
        tempfile.flush
        Docx::Document.open(tempfile.path).paragraphs.map(&:text).join("\n")
      end
      text = text.to_s.strip.first(Extractor::MAX_TEXT_CHARS)
      raise CvParsing::EmptyContent, "CV contained no readable text" if text.blank?

      { kind: :text, payload: text }
    rescue Zip::Error, Errno::ENOENT, StandardError => e
      raise e if e.is_a?(CvParsing::EmptyContent) || e.is_a?(Unsupported)
      raise Unsupported, "DOCX could not be read"
    end
  end
end
