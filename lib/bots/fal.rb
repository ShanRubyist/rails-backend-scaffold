require 'faraday'
require 'bot'

module Bot
  class Fal < AIModel
    def initialize(secret_key = ENV.fetch('FAL_API_KEY'), api_base_url = 'https://queue.fal.run')
      @secret_key = secret_key
      @api_base_url = api_base_url
    end

    def video_api(message, options = {})
      callback_url = options.fetch(:callback_url, "https://#{ENV.fetch('HOST')}/gen_callback")
      path = options.fetch(:path, "/fal-ai/veo2?fal_webhook=#{callback_url}")
      image_url = options.fetch(:image_url, nil)

      resp = client.post(path) do |req|
        req.headers['Content-Type'] = 'application/json'
        req.headers['Authorization'] = "Key #{@secret_key}"

        req.body = {
          prompt: message,
          images: [
            {
              image_url: image_url
            }
          ]
        }.to_json
      end
      h = JSON.parse(resp.body)
      if h['request_id']
        return h['request_id']
      else
        fail h.to_json
      end
    end

    def callback(payload)
      # return if payload['status'] != 'OK'

      request_id = payload['request_id']
      ai_call = AiCall.find_by_task_id(request_id)

      if ai_call
        payload['video'] = payload['payload']['video']['url'] rescue nil
        ai_call.update!(
          status: payload['status'],
          data: payload
        )
        if payload['status'] == 'OK'
          # OSS
          require 'open-uri'
          SaveToOssJob.perform_later(ai_call,
                                     :generated_media,
                                     {
                                       io: URI.open(payload['video']),
                                       filename: URI(payload['video']).path.split('/').last,
                                       content_type: "video/mp4"
                                     }
          )
        end
      else
        # fail "[FAL API]task id not exist"
      end
    end

    private

    def query_video_task_api(req_id)
      path = "/fal-ai/pika/requests/#{req_id}/status"

      resp = client.get(path) do |req|
        req.headers['Content-Type'] = 'application/json'
        req.headers['Authorization'] = "Key #{@secret_key}"
      end

      if resp.success?
        # puts "query status: "
        # puts resp.body
        h = JSON.parse(resp.body)
        if h['status'] == 'COMPLETED'
          return {
            status: 'success',
            video: retrieve_video_file(req_id),
            data: h
          }
        elsif h['status'] == 'failed'
          fail 'generate video failed'
        else
          {
            status: h['status'],
            video: retrieve_video_file(req_id),
            data: h
          }
        end
      else
        fail 'query video status error'
      end
    end

    def retrieve_video_file(req_id)
      path = "fal-ai/pika/requests/#{req_id}"

      resp = client.get(path) do |req|
        req.headers['Content-Type'] = 'application/json'
        req.headers['Authorization'] = "Key #{@secret_key}"
      end

      if resp.success?
        h = JSON.parse(resp.body)
        h['video']['url']
      else
        fail 'retrieve video file error'
      end
    end

    def client
      @client ||= Faraday.new(url: @api_base_url)
    end
  end
end
