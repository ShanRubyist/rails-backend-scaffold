require "ruby/openai"
require 'bot'

module Bot
  class OpenAI < AIModel
    def initialize(api_key = ENV.fetch('OPENAI_API_KEY'), api_base_url = 'https://api.openai.com/', organization_id = '')
      @client = openai_client(api_key, api_base_url, organization_id)
      @model = 'o1-mini'
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

    # https://platform.openai.com/docs/api-reference/audio/createSpeech
    def audio_api(content, options = {})
      model = options.fetch(:model, 'gpt-4o-mini-tts')
      voice = options.fetch(:voice, 'alloy')
      instructions = options.fetch(:instructions, nil)
      speed = options.fetch(:speed, 1.0)
      response_format = options.fetch(:response_format, "mp3")

      response = @client.audio.speech(
        parameters: {
          model: model,
          input: content,
          voice: voice,
          instructions: instructions, # Optional
          response_format: response_format, # Optional
          speed: speed, # Optional
        }
      )

      response
      # Controller 中可以设置响应头为音频格式
      # send_data(
      #   audio_data,
      #   filename: "tts_audio.mp3",
      #   type: "audio/mpeg",
      #   disposition: "inline"
      # )
    end

    private

    def openai_client(access_token, uri_base, organization_id = '', request_timeout = 240)
      ::OpenAI.configure do |config|
        config.access_token = access_token
        config.uri_base = uri_base
        config.organization_id = organization_id
        config.request_timeout = request_timeout
      end

      ::OpenAI::Client.new
    end
  end
end