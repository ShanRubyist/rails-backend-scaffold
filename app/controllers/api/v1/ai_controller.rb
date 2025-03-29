require 'bot'

class Api::V1::AiController < UsageController
  skip_before_action :check_credits, only: [:ai_call_info]

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

  def ai_call_info
    params[:page] ||= 1
    params[:per] ||= 20

    ai_calls = AiCall.joins(conversation: :user).where(users: { id: current_user.id })
                 .order("created_at desc")
                 .page(params[:page].to_i)
                 .per(params[:per].to_i)

    result = ai_calls.map do |item|
      {
        input_media: (
          item.input_media.map do |media|
            url_for(media)
          end
        ),
        generated_media: (
          item.generated_media.map do |media|
            url_for(media)
          end
        ),
        prompt: item.prompt,
        status: item.status,
        input: item.input,
        data: item.data,
        created_at: item.created_at,
        cost_credits: item.cost_credits,
        system_prompt: item.system_prompt,
        business_type: item.business_type
      }
    end

    render json: {
      total: ai_calls.total_count,
      histories: result
    }
  end

end