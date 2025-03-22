module Bot
  class AIModel
    def initialize(api_key, api_base_url)
      @api_key = api_key
      @api_base_url = api_base_url
    end

    def completion(message, prompt = nil, options = {}, &block)
      handle(message, prompt, options) do |chunk, _overall_received_bytes, _env|
        fail chunk.to_s if _env && _env.status != 200

        if @stream
          rst = resp(chunk)
          if rst.is_a?(Array)
            rst.each { |item| yield item, chunk }
          elsif rst
            yield rst, chunk
          end
        end
      end
    end

    private

    def resp(msg)
      msg
    end
  end
end

require 'bots/openai'
require 'bots/openrouter'
require 'bots/baidu'
require 'bots/mini_max'
require 'bots/thebai'
require 'bots/ali'
require 'bots/moonshot'
require 'bots/gemini'
require 'bots/smarttrot'


