require 'faraday'
require 'bot'

module Bot
  class Ali < AIModel
    def initialize(api_key=ENV.fetch('OPENAI_API_KEY'), api_base_url = 'https://dashscope.aliyuncs.com')
      @api_key = api_key
      @api_base_url = api_base_url
      @path = '/api/v1/services/aigc/text-generation/generation'
      @model = nil
    end

    def text_api(message, options = {}, &block)
      @temperature = options.fetch(:temperature, 0.95)
      @top_p = options.fetch(:top_p, 0.8)
      @enable_search = true
      @incremental_output = true
      @stream = true
      prompt = options.fetch(:prompt, nil)

      client.post(@path) do |req|
        req.headers['Content-Type'] = 'application/json'
        req.headers['Accept'] = 'text/event-stream' if @stream
        req.headers['Authorization'] = "Bearer #{@api_key}"
        req.body = {
          model: @model,
          input: {
            prompt: prompt.to_s,
            messsages: [
              {
                role: 'user',
                content: message.to_s
              }
            ]
          },
          parameters: {
            result_format: 'message',
            top_p: @top_p,
            temperature: @temperature,
            enable_search: @enable_search,
            incremental_output: @incremental_output
          }
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
        json = JSON.parse(data)
        msg = json['output']
        return if msg.nil?

        choices = msg['choices']
        choices_message = choices&.first&.fetch('message', {})
        choices_finish_reason = choices&.first&.fetch('finish_reason', nil)
        rst << {
          "id": msg['request_id'],
          "object": '',
          "created": Time.now,
          "model": @model,
          "choices": [
            {
              "index": nil,
              "delta": {
                "role": choices_message['role'],
                "content": choices_message['content']# ? choices_message['content'] : ''
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

    # def connect
    #   connection = Faraday.new(url: @url) do |builder|
    #     # Calls MyAuthStorage.get_auth_token on each request to get the auth token
    #     # and sets it in the Authorization header with Bearer scheme.
    #     builder.request :authorization, 'Bearer', -> {@authorization}
    #
    #     # Sets the Content-Type header to application/json on each request.
    #     # Also, if the request body is a Hash, it will automatically be encoded as JSON.
    #     builder.request :json
    #
    #     # Parses JSON response bodies.
    #     # If the response body is not valid JSON, it will raise a Faraday::ParsingError.
    #     builder.response :json
    #
    #     # Raises an error on 4xx and 5xx responses.
    #     builder.response :raise_error
    #
    #     # Logs requests and responses.
    #     # By default, it only logs the request method and URL, and the request/response headers.
    #     builder.response :logger
    #   end
    # end
  end
end


