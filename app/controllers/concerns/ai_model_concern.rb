module AiModelConcern
  extend ActiveSupport::Concern

  included do |base|
  end

  def save_to_db(h)
    user = h.fetch(:user)
    model_name = h.fetch(:model_name)
    aspect_ratio = h.fetch(:aspect_ratio)
    prompt = h.fetch(:prompt) { nil }
    data = h.fetch(:data) { {} }
    output = data.fetch("output")
    predict_id = data.fetch("id")
    if data.fetch('status') == 'succeeded'
      cost_credits =
        case model_name
        when nil
          1
        else
          Lora.find_by(value: model_name).cost_credits
        end
    else
      cost_credits = 0
    end

    user
      .replicated_calls
      .create_with(data: data, output: output, prompt: prompt, aspect_ratio: aspect_ratio, cost_credits: cost_credits, model: model_name)
      .find_or_create_by(predict_id: predict_id)

    if output.is_a?(Array)
      image = output.first
    else
      image = output
    end

    image

  rescue => e
    puts e
  end

  module ClassMethods
  end
end
