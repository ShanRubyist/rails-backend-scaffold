require "ruby/openai"
require 'bot'

module Bot
  class Groq < AIModel
    def initialize(api_key = ENV.fetch('GROQ_API_KEY'), api_base_url = 'https://api.groq.com/openai')
      @client = openai_client(api_key, api_base_url)
      @model = 'llama3-8b-8192'
    end

    def text_api(content, options = {}, &block)
      @model = options.fetch(:model, @model)
      @temperature = options.fetch(:temperature, 1)
      @top_p = options.fetch(:top_p, 1)
      @stream = options.fetch(:stream, false)
      prompt = options.fetch(:prompt, nil)

      message = []
      message.push({ "role": "system", "content": prompt }) if prompt
      message.push({ "role": "user", "content": content })

      parameters = {
        model: @model,
        messages: message,
        # temperature: @temperature,
        # top_p: @top_p,
      }

      if @stream
        parameters[:stream] = proc do |chunk, _bytesize|
          yield chunk, _bytesize
        end
      end
      @client.chat(parameters: parameters)
    end

    private

    def openai_client(access_token, uri_base, request_timeout = 240)
      ::OpenAI.configure do |config|
        config.access_token = access_token
        config.uri_base = uri_base
        config.request_timeout = request_timeout
      end

      ::OpenAI::Client.new
    end
  end
end