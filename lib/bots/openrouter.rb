require 'faraday'

module Bot
  class OpenRouter < AIModel
    def initialize(api_key=ENV.fetch('OPENROUTER_API_KEY'), api_base_url = 'https://openrouter.ai')
      @api_key = api_key
      @api_base_url = api_base_url
      @path = '/api/v1/chat/completions'
      @model = 'openai/o1-mini'
      @buff = ''
    end

    def text_api(message, options = {}, &block)
      @stream = options.fetch(:stream, false)
      @temperature = options.fetch(:temperature, 0.95)
      @top_p = options.fetch(:top_p, 0.8)
      prompt = options.fetch(:prompt, nil)

      resp = client.post(@path) do |req|
        req.headers['Authorization'] = "Bearer #{@api_key}"
        req.headers['Content-Type'] = 'application/json'
        req.headers['HTTP-Referer'] = ENV.fetch('REDIRECT_SUCCESS_URL') # Optional, for including your app on open_router.ai rankings.
        req.headers['X-Title'] = 'YuanFang' # Optional. Shows in rankings on open_router.ai.

        req.body = {
          model: @model,
          stream: @stream,
          model_params: {
            temperature: @temperature,
            top_p: @top_p,
          },
          "messages": [
            { "role": "user", "content": prompt.to_s + message.to_s }
          ]
        }.to_json

        req.options.on_data = block if @stream
      end

      # if response.success?
      # yield data
      # else
      # @error_message = 'Failed to get data'
      # end

      JSON.load(resp.body) unless @stream
    end

    private

    def client
      @client ||= Faraday.new(url: @api_base_url)
    end

    def text_resp(data)
      rst = []
      data = @buff.force_encoding('ASCII-8BIT') + data unless @buff.empty?
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


