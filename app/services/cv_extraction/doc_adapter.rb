require "open3"

module CvExtraction
  class DocAdapter
    def self.call(document)
      text = Tempfile.create([ "cv", ".doc" ], binmode: true) do |tempfile|
        tempfile.write(document.file.download)
        tempfile.flush
        stdout, _stderr, status = Open3.capture3("textutil", "-convert", "txt", "-stdout", tempfile.path)
        raise Unsupported, "Legacy .doc could not be read" unless status.success?
        stdout
      end
      text = text.to_s.strip.first(Extractor::MAX_TEXT_CHARS)
      raise Unsupported, "Legacy .doc could not be read" if text.blank?

      { kind: :text, payload: text }
    rescue Errno::ENOENT
      raise Unsupported, "Legacy .doc could not be read"
    end
  end
end
