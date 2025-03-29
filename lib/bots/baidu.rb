require 'faraday'
require 'bot'

module Bot
  class Baidu < AIModel
    def initialize(api_key, secret_key, api_base_url = 'https://aip.baidubce.com')
      @api_key = api_key
      @secret_key = secret_key
      @api_base_url = api_base_url
      @path = ''
    end

    def text_api(message, options = {}, &block)
      @stream = options.fetch(:stream, false)
      @temperature = options.fetch(:temperature, 0.95)
      @top_p = options.fetch(:top_p, 0.8)
      prompt = options.fetch(:prompt, nil)

      client.post(@path) do |req|
        req.params['access_token'] = access_token
        req.headers['Content-Type'] = 'application/json'
        req.body = {
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
      # yield data
      # else
      @error_message = 'Failed to get data'
      # end
    end

    private

    def client
      @client ||= Faraday.new(url: @api_base_url)
    end

    def access_token
      # TODO: reuse access_token until outdate
      url = "https://aip.baidubce.com/oauth/2.0/token"

      response = client.post(url) do |req|
        req.headers['Content-Type'] = 'application/json'
        req.params['grant_type'] = 'client_credentials'
        req.params['client_id'] = @api_key
        req.params['client_secret'] = @secret_key
      end
      data = JSON.parse(response.body)

      data.fetch('access_token')
    end

    def text_resp(data)
      # 接口返回的 HTTP STATUS 还是 200，只能根据返回内容判断
      fail data unless data.scan(/error_code/).empty?

      rst = []
      data.scan(/(?:data|error):\s*(\{.*\})/i).flatten.each do |data|
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
                "content": msg['result']
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


