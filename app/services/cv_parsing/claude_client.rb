module CvParsing
  class ClaudeClient
    def extract(extracted)
      message = client.messages.create(
        model: Rails.application.config.x.claude_model,
        max_tokens: 4096,
        system_: ExtractionSchema::SYSTEM_PROMPT,
        tools: [ {
          name: ExtractionSchema::TOOL_NAME,
          description: "Structured candidate data extracted from the CV.",
          input_schema: ExtractionSchema::INPUT
        } ],
        tool_choice: { type: "tool", name: ExtractionSchema::TOOL_NAME },
        messages: [ { role: "user", content: build_content(extracted) } ]
      )
      parse_tool_result(message)
    rescue Anthropic::Errors::APIConnectionError, Anthropic::Errors::RateLimitError,
           Anthropic::Errors::InternalServerError => e
      raise RetryableApiError, e.message
    rescue Anthropic::Errors::APIError => e
      raise NonRetryableApiError, e.message
    end

    private

    def client
      api_key = ENV["ANTHROPIC_API_KEY"].presence
      raise NonRetryableApiError, "Claude API key not configured" unless api_key

      @client ||= Anthropic::Client.new(api_key: api_key, timeout: 120, max_retries: 0)
    end

    def build_content(extracted)
      case extracted[:kind]
      when :pdf_bytes
        [
          { type: "document",
            source: { type: "base64", media_type: "application/pdf",
                      data: Base64.strict_encode64(extracted[:payload]) } },
          { type: "text", text: "Extract the candidate data from this CV using the tool." }
        ]
      else
        [ { type: "text", text: "Extract the candidate data from this CV using the tool.\n\n#{extracted[:payload]}" } ]
      end
    end

    def parse_tool_result(message)
      tool_use = message.content.find { |block| block.type.to_s == "tool_use" }
      raise EmptyContent, "No structured data returned" unless tool_use

      result = JSON.parse(JSON.generate(tool_use.input))
      raise EmptyContent, "CV contained no extractable data" if all_values_null?(result)

      result
    end

    def all_values_null?(result)
      result.all? do |_field, node|
        case node
        when Hash then node["value"].nil?
        when Array then node.empty?
        else node.nil?
        end
      end
    end
  end
end
