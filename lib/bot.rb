module Bot
  class AIModel
    def initialize(api_key, api_base_url)
      @api_key = api_key
      @api_base_url = api_base_url
    end

    def generate_text(message, options = {}, &block)
      text_api(message, options) do |chunk, _overall_received_bytes, _env|
        fail chunk.to_s if _env && _env.status != 200

        if options.fetch(:stream, false)
          rst = text_resp(chunk)
          if rst.is_a?(Array)
            rst.each { |item| yield item, chunk }
          elsif rst
            yield rst, chunk
          end
        end
      end
    end

    def generate_image(message, options = {})
      image_api(message, options)
    end

    def query_image_task(task_id, &block)
      rst = {}
      while true
        rst = query_image_task_api(task_id)
        yield rst
        break if rst[:image]
        sleep 1
      end
      rst[:image]
    end

    def generate_audio(message, options = {}, &block)
      audio_api(message, options)
    end

    def generate_video(message, options = {})
      task_id = video_api(message, options)
    end

    def query_video_task(task_id, &block)
      rst = {}
      while true
        rst = query_video_task_api(task_id)
        yield rst
        break if rst[:video]
        sleep 1
      end
      rst[:video]
    end

    private

    def text_resp(msg)
      msg
    end

    def image_resp(msg)
      msg
    end
  end
end

require 'bots/openai'
require 'bots/deepseek'
require 'bots/groq'
require 'bots/openrouter'
require 'bots/baidu'
require 'bots/mini_max'
require 'bots/thebai'
require 'bots/ali'
require 'bots/moonshot'
require 'bots/gemini'
require 'bots/smarttrot'
require 'bots/kling'
require 'bots/fal'
require 'bots/replicate'


