require 'bot'

class Api::V1::AiController < UsageController
  def gen_video
    conversation = current_user.conversations.create

    # generate video task
    ai_bot = Bot::Fal.new
    task_id = ai_bot.generate_video(prompt,
                                    image_url: params[:image_url],
                                    path: params[:path])

    ai_call = conversation.ai_calls.create(
      task_id: task_id,
      prompt: params[:prompt],
      status: 'submit',
      input: params,
      "cost_credits": current_cost_credits)

    # query video task status
    video = ai_bot.query_video_task(task_id) do |h|
      ai_call.update_ai_call_status(h)
    end

    # OSS
    require 'open-uri'
    ai_call.generated_media.attach(io: URI.open(video),
                                   filename: URI(video).path.split('/').last,
                                   content_type: "video/mp4")

    render json: {
      videos: (
        ai_call.generated_media.map do |i|
          url_for(i)
        end
      )
    }
  end
end