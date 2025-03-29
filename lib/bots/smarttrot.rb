require 'faraday'
require 'bot'

module Bot
  module Smarttrot
    class Smarttrot < AIModel
      def initialize(api_key, api_base_url = 'https://flag.smarttrot.com')
        @api_key = api_key
        @api_base_url = api_base_url
        @path = '/v1/chat/completions'
      end

      def text_api(message, options = {}, &block)
        @stream = options.fetch(:stream, true)
        @temperature = options.fetch(:temperature, 0.5)
        @top_p = options.fetch(:top_p, 0.5)
        prompt = options.fetch(:prompt, nil)

        client.post(@path) do |req|
          req.headers['Content-Type'] = 'application/json'
          req.headers['Authorization'] = "Bearer #{@api_key}"

          req.body = {
            model: @model,
            stream: @stream,
            temperature: @temperature,
            top_p: @top_p,
            "messages": [
              { "role": "user", "content": prompt.to_s + message.to_s }
            ]
          }.to_json

          req.options.on_data = block
        end

        # if response.success?
        #   yield response.body
        # else
        #   @error_message = 'Failed to get data'
        # end
      end

      private

      def client
        @client ||= Faraday.new(url: @api_base_url)
      end

      def text_resp(data)
        # 接口返回的 HTTP STATUS 还是 200，只能根据返回内容判断
        fail data unless data.scan(/error_code/).empty?

        rst = []
        data.scan(/(?:data|error):\s*(\{.*\})/i).flatten.each do |data|
          # puts data

          msg = JSON.parse(data)
          return if msg.empty?

          rst << {
            "id": msg['id'],
            "object": msg['object'],
            "created": msg['created'],
            "model": msg['model'] || 'gpt-3.5-turbo',
            "choices": [
              {
                "index": msg['sentence_id'],
                "delta": {
                  "content": msg['choices'][0]['delta']['content']
                },
                "finish_reason": msg['is_end'] ? "stop" : nil
              }
            ],
            "is_truncated": msg['is_truncated']
          }
          # rescue JSON::ParserError
          # Ignore invalid JSON.
        end
        rst
      end
    end
  end
end


