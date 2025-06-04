require 'faraday'
require 'bot'

module Bot
  class Kling < AIModel
    def initialize(secret_key = ENV.fetch('KLING_API_KEY'), api_base_url = 'https://api.klingai.com/')
      @secret_key = secret_key
      @api_base_url = api_base_url
    end

    def video_api(message, options = {})
      path = options.fetch(:path, '/v1/videos/text2video')
      model = options.fetch(:model, 'kling-v1')
      callback_url = options.fetch(:callback_url, "https://#{ENV.fetch('HOST')}/gen_callback")

      resp = client.post(path) do |req|
        req.headers['Content-Type'] = 'application/json'
        req.headers['Authorization'] = "Bearer #{@secret_key}"

        req.body = {
          model: model,
          prompt: message,
          callback_url: callback_url
        }.to_json
      end
      h = JSON.parse(resp.body)
      if h['data'] && h['data']['task_id']
        return h['data']['task_id']
      else
        fail h.to_json
      end
    end

    def callback(payload)
      return if payload['task_status'] != 'succeed' && payload['task_status'] != 'failed'

      task_id = payload['task_id']
      ai_call = AiCall.find_by_task_id(task_id)

      if ai_call
        payload['video'] = payload['task_result']['videos']&.first['url'] rescue nil
        ai_call.update!(
          status: payload['task_status'],
          data: payload
        )
        if payload['task_status'].downcase == 'succeed'
          # OSS
          require 'open-uri'
          SaveToOssJob.perform_later(ai_call,
                                     :generated_media,
                                     {
                                       io: payload['video'],
                                       filename: URI(payload['video']).path.split('/').last,
                                       content_type: "video/mp4"
                                     }
          )
        end
      else
        # fail "[KLING API]task id not exist"
      end
    end

    private

    def query_video_task_api(task_id)
      path = "/v1/videos/text2video/#{task_id}"

      resp = client.get(path) do |req|
        req.headers['Content-Type'] = 'application/json'
        req.headers['Authorization'] = "Bearer #{@secret_key}"
      end

      if resp.success?
        puts "query status: "
        puts resp.body
        h = JSON.parse(resp.body)
        if h['data']['task_status'] == 'succeed'
          return {
            status: 'success',
            video: h['data']['task_result']['videos'].first.fetch('url'),
            data: h
          }
        elsif h['data']['task_status'] == 'failed'
          fail 'generate video failed'
        else
          return {
            status: h['status'],
            video: retrieve_video_file(task_id),
            data: h
          }
        end
      else
        fail 'query video status error'
      end
    end

    def client
      @client ||= Faraday.new(url: @api_base_url)
    end
  end
end
