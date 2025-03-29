require 'faraday'
require 'bot'

module Bot
  class Moonshot < AIModel
    def initialize(api_key, api_base_url = 'https://api.moonshot.cn')
      @api_key = api_key
      @api_base_url = api_base_url
      @path = '/v1/chat/completions'
      @model = ''
    end

    def text_api(content, options = {}, &block)
      @stream = options.fetch(:stream, true)
      @temperature = options.fetch(:temperature, 0.95)
      @top_p = options.fetch(:top_p, 0.8)
      prompt = options.fetch(:prompt, nil)

      message = []
      message.push({ "role": "system", "content": prompt.to_s }) if prompt
      message.push({ "role": "user", "content": content.to_s })

      client.post(@path) do |req|
        req.headers['Authorization'] = "Bearer #{@api_key}"
        req.headers['Content-Type'] = 'application/json'
        req.body = {
          model: @model,
          stream: @stream,
          temperature: @temperature,
          top_p: @top_p,
          messages: message
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

    def text_resp(data)
      rst = []
      data.scan(/(?:data|error):\s*(\{.*\})/i).flatten.each do |data|
        msg = JSON.parse(data)
        return if msg.empty?
        choices = msg['choices']
        choices_message = choices&.first&.fetch('delta', {})
        choices_finish_reason = choices&.first&.fetch('finish_reason', nil)

        rst << {
          "id": msg['id'],
          "object": msg['object'],
          "created": msg['created'],
          "model": msg['model'],
          "choices": [
            {
              "index": choices_message['index'],
              "delta": {
                "role": choices_message['role'],
                "content": choices_message['content'] ? choices_message['content'] : ''
              },
              "finish_reason": choices_finish_reason
            }
          ]
        }
        # rescue JSON::ParserError
        # Ignore invalid JSON.
      end
      rst
    end
  end
end


