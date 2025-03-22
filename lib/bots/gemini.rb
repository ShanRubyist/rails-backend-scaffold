require 'faraday'

module Bot
  class Gemini < AIModel
    def initialize(api_key, api_base_url = 'https://generativelanguage.googleapis.com')
      @api_key = api_key
      @api_base_url = api_base_url
      @path = '/v1beta/models/gemini-pro:streamGenerateContent?alt=sse&key=' + @api_key
      @buff = ''
    end

    def handle(content, prompt = nil, options = {}, &block)
      @stream = options.fetch(:stream, true)
      @temperature = options.fetch(:temperature, 0.95)
      @top_p = options.fetch(:top_p, 0.8)

      message = []
      message.push({ "role": "user", "parts": [{ "text": prompt.to_s + content.to_s }] })

      client.post(@path) do |req|
        req.headers['Content-Type'] = 'application/json'
        req.body = {
          contents: message
        }.to_json
        req.options.on_data = block
      end

      # if response.success?
      # yield data
      # else
      @error_message = 'Failed to get data'
      # end
    end

    private

    def client
      @client ||= Faraday.new(url: @api_base_url)
    end

    def resp(data)
      rst = []
      data = @buff.force_encoding('ASCII-8BIT') + data unless @buff.empty?
      data.scan(/(?:data|error):\s*(\{.*\})/i).flatten.each do |str|
        begin
          msg = JSON.parse(str)
        rescue
          @buff = data
          return nil
        end

        @buff = ''
        return unless msg
        candidate = msg['candidates']&.first
        return unless candidate

        content = candidate['content']
        part = content['parts']&.first rescue nil

        rst << {
          "choices": [
            {
              "index": 0,
              "delta": {
                "role": content['role'],
                "content": part['text'] ? part['text'] : ''
              },
              "finish_reason": candidate['finishReason']
            }
          ]
        }
      end
      rst
    end
  end
end


