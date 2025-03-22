module Bot
  class Replicate < AIModel
    def initialize
    end

    def generate_image(prompt, model_name, aspect_ratio)
      model = Replicate.client.retrieve_model(model_name)

      version = model.latest_version
      begin
        # webhook_url = "https://" + ENV.fetch("HOST") + "/replicate/webhook"
        prediction = version.predict(prompt: prompt, aspect_ratio: aspect_ratio, disable_safety_checker: true) #, safety_tolerance: 5)
        data = prediction.refetch

        until prediction.finished? do
          sleep 1
          data = prediction.refetch
        end

        raise data.fetch('error') if prediction.failed? || prediction.canceled?

      ensure
        # params.permit(:prompt, :aspect_ratio, :model, :replicate)
        SavePicToOssJob.perform_later({ user: current_user, model_name: model_name, aspect_ratio: aspect_ratio, prompt: prompt, data: data })
      end

      prediction.output
    end
  end
end