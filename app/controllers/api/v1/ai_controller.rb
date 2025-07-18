require 'bot'

class Api::V1::AiController < UsageController
  skip_around_action :check_credits, only: [:ai_call_info, :gen_callback, :gen_task_status]
  skip_before_action :check_if_maintenance_mode, only: [:ai_call_info, :gen_callback, :gen_task_status]

  def gen_image
    type = params['type']
    raise 'type can not be empty' unless type.present?

    prompt = params['prompt'] || 'GHBLI anime style photo'
    raise 'prompt can not be empty' unless prompt.present?

    image = params['image']
    raise 'image can not be empty' unless image.present?

    model_name = 'aaronaftab/mirage-ghibli'

    conversation = current_user.conversations.create
    ai_call = conversation.ai_calls.create(
      task_id: SecureRandom.uuid,
      prompt: prompt,
      status: 'submit',
      input: params,
      "cost_credits": current_cost_credits)

    if type.to_i == 0
      # OSS
      SaveToOssJob.perform_now(ai_call,
                               :input_media,
                               {
                                 io: image.tempfile,
                                 filename: image.original_filename + Time.now.to_s,
                                 content_type: image.content_type
                               }
      )
      image = url_for(ai_call.input_media.last)
    end

    task = ai_bot.generate_image(prompt, image: image, model_name: model_name)

    # query task status
    images = ai_bot.query_image_task(task) do |h|
      ai_call.update_ai_call_status(h)
    end

    # OSS
    require 'open-uri'
    SaveToOssJob.perform_later(ai_call,
                               :generated_media,
                               {
                                 io: images.first,
                                 filename: URI(image).path.split('/').last,
                                 content_type: "image/jpeg"
                               }
    )

    render json: {
      images: images
    }
  end

  def gen_video
    conversation = current_user.conversations.create
    prompt = params['prompt']

    # generate video task
    task_id = ai_bot.generate_video(prompt)

    task_id = task_id.id if ai_bot.class == Bot::Replicate

    ai_call = conversation.ai_calls.create(
      task_id: task_id,
      prompt: params[:prompt],
      status: 'submit',
      input: params,
      "cost_credits": current_cost_credits)

    render json: {
      task_id: task_id
    }
  end

  def gen_callback
    begin
      AigcWebhook.create!(data: request.body.read)

      # TODO: perform later & destroy AigcWebhook record
      rst = ai_bot.webhook_callback(params)

      if rst && (rst.class == String)
        # For HaiLuo Video
        render json: rst
      else
        head :ok
      end
      # rescue
      #   head :bad_request
    end
  end

  def gen_task_status
    task_id = params['task_id']
    ai_call = AiCall.find_by_task_id(task_id)

    if ai_call
      payload = ai_call.data

      render json: {
        status: ((payload['status'] || payload['data']['status']) rescue nil),
        video: ((payload['video'] || payload['data']['output']) rescue nil)
      }
    else
      fail "[Controller]task id not exist"
    end

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
        # input_media: (
        #   item.input_media.map do |media|
        #     url_for(media)
        #   end
        # ),
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

  private

  def ai_bot
    Bot::Fal.new
    Bot::Replicate.new
  end
end