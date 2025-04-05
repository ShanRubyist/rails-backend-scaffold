require 'faraday'
require 'bot'

module Bot
  class MiniMax < AIModel
    def initialize(group_id = ENV.fetch('MINIMAX_GROUP_ID'), secret_key = ENV.fetch('MINIMAX_API_KEY'), api_base_url = 'https://api.minimax.chat')
      @group_id = group_id
      @secret_key = secret_key
      @api_base_url = api_base_url
      @path = '/v1/text/chatcompletion_pro'
    end

    def text_api(message, options = {}, &block)
      @model = options.fetch(:model, 'abab5.5-chat')
      @stream = options.fetch(:stream, true)
      @temperature = options.fetch(:temperature, 0.5)
      @top_p = options.fetch(:top_p, 0.5)
      @mask_sensitive_info = options.fetch(:mask_sensitive_info, false)
      prompt = options.fetch(:prompt, nil)

      client.post(@path) do |req|
        req.params['GroupId'] = @group_id

        req.headers['Content-Type'] = 'application/json'
        req.headers['Authorization'] = "Bearer #{@secret_key}"

        req.body = {
          model: @model,
          stream: @stream,
          tokens_to_generate: 1024,
          temperature: @temperature,
          top_p: @top_p,
          mask_sensitive_info: @mask_sensitive_info,
          "bot_setting": [
            {
              "bot_name": "MM智能助理",
              "content": 'MM智能助理是一款由MiniMax自研的，没有调用其他产品的接口的大型语言模型。MiniMax是一家中国科技公司，一直致力于进行大模型相关的研究。'
            }
          ],
          "messages": [
            { "sender_type": "USER", "sender_name": "Yuanfang", "text": prompt.to_s + message.to_s }
          ],
          "reply_constraints": { "sender_type": "BOT", "sender_name": "MM智能助理" },
        }.to_json

        req.options.on_data = block if @stream
      end

      # if response.success?
      #   yield response.body
      # else
      #   @error_message = 'Failed to get data'
      # end
    end

    # TODO: Callback 方式还不支持
    def video_api(message, options = {})
      path = options.fetch(:path, '/v1/video_generation')
      model = options.fetch(:model, 'T2V-01-Director')
      prompt_optimizer = options.fetch(:prompt_optimizer, nil)
      first_frame_image = options.fetch(:first_frame_image, nil)
      callback_url = options.fetch(:callback_url, nil)

      resp = client.post(path) do |req|
        req.params['GroupId'] = @group_id
        req.headers['Content-Type'] = 'application/json'
        req.headers['Authorization'] = "Bearer #{@secret_key}"

        req.body = {
          model: model,
          prompt_optimizer: prompt_optimizer,
          first_frame_image: first_frame_image,
          callback_url: callback_url,
          prompt: message,
        }.to_json
      end
      h = JSON.parse(resp.body)
      h['task_id']
      if h['task_id']
        return h['task_id']
      else
        fail h.to_json
      end
    end

    private

    def query_video_task_api(task_id)
      path = "/v1/query/video_generation?task_id=#{task_id}"

      resp = client.get(path) do |req|
        req.headers['Content-Type'] = 'application/json'
        req.headers['Authorization'] = "Bearer #{@secret_key}"
      end

      if resp.success?
        # puts "query status: "
        # puts resp.body
        h = JSON.parse(resp.body)
        if h['status'] == 'Sucess'
          return {
            status: 'success',
            video: retrieve_video_file(h['file_id']),
            data: h
          }
        elsif h['status'] == 'Failed'
          fail 'generate video failed'
        else
          return {
            status: h['status'],
            video: retrieve_video_file(h['file_id']),
            data: h
          }
        end
      else
        fail 'query video status error'
      end
    end

    def retrieve_video_file(file_id)
      path = "/v1/files/retrieve?GroupId=#{@group_id}&file_id=#{file_id}"

      resp = client.get(path) do |req|
        req.headers['authority'] = 'api.minimaxi.chat'
        req.headers['Content-Type'] = 'application/json'
        req.headers['Authorization'] = "Bearer #{@secret_key}"
      end

      if resp.success?
        h = JSON.parse(resp.body)
        h['file']['download_url']
      else
        fail 'retrieve video file error'
      end
    end

    def client
      @client ||= Faraday.new(url: @api_base_url)
    end

    def text_resp(data)
      # 接口返回的 HTTP STATUS 还是 200，只能根据返回内容判断
      fail data unless data.scan(/base_resp/).empty?

      rst = []
      data.scan(/(?:data|error):\s*(\{.*\})/i).flatten.each do |data|
        msg = JSON.parse(data)

        return unless msg && msg.present?

        choices = msg['choices']
        choices_message = choices&.first&.fetch('messages', [{}])&.first
        choices_finish_reason = choices&.first&.fetch('finish_reason', nil)

        rst << {
          "id": msg['id'],
          "object": msg['object'],
          "created": msg['created'],
          "model": msg['model'] || 'gpt-3.5-turbo',
          "choices": [
            {
              "index": 0,
              "delta": {
                "content": (choices_finish_reason != "stop" ? choices_message['text'] : '') # 需要判断是否为最后一条消息，需要过滤。因为 MimiMax 最后还会返回一次完整的内容
              },
              "finish_reason": (choices_finish_reason ? choices_finish_reason : nil)
            }
          ],
          "input_sensitive": msg['input_sensitive'],
          "output_sensitive": msg['output_sensitive'],
          "reply": msg['reply']
        }
        # rescue JSON::ParserError
        # Ignore invalid JSON.
      end
      rst
    end
  end
end
