require 'faraday'
require 'bot'

module Bot
  class Gemini < AIModel
    def initialize(api_key = ENV.fetch('GEMINI_API_KEY'), api_base_url = 'https://generativelanguage.googleapis.com')
      @api_key = api_key
      @api_base_url = api_base_url

      @buff = ''
    end

    def text_api(content, options = {}, &block)
      path = options.fetch(:path, '/v1beta/models/gemini-2.0-flash:generateContent')
      @path = @stream ? "#{path}?alt=sse&key=#{@api_key}" : "#{path}?key=#{@api_key}"

      @stream = options.fetch(:stream, false)
      @temperature = options.fetch(:temperature, 0.95)
      @top_p = options.fetch(:top_p, 0.8)
      prompt = options.fetch(:prompt, nil)

      message = []
      message.push({ "role": "user", "parts": [{ "text": prompt.to_s + content.to_s }] })

      resp = client.post(@path) do |req|
        req.headers['Content-Type'] = 'application/json'
        req.body = {
          contents: message
        }.to_json

        req.options.on_data = block if @stream
      end

      # if response.success?
      # yield data
      # else
      # @error_message = 'Failed to get data'
      # end

      # TODO: 这个返回值与openai格式不同
      JSON.load(resp.body) unless @stream
    end

    def image_api(content, options = {})
      path = options.fetch(:path, '/v1beta/models/gemini-2.0-flash-exp-image-generation:generateContent')
      path += "?key=#{@api_key}"

      prompt = options.fetch(:prompt, nil)
      message = []
      message.push({ "role": "user", "parts": [{ "text": prompt.to_s + content.to_s }] })

      resp = client.post(path) do |req|
        req.headers['Content-Type'] = 'application/json'
        req.body = {
          contents: message,
          generationConfig: {
            responseModalities: ["Text", "Image"]
          }

        }.to_json
      end

      # if response.success?
      # yield data
      # else
      # @error_message = 'Failed to get data'
      # end

      JSON.load(resp.body)
    end

    private

    def client
      @client ||= Faraday.new(url: @api_base_url)
    end

    def text_resp(data)
      rst = []

      h = JSON.parse(data)

      h.each do |msg|
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


