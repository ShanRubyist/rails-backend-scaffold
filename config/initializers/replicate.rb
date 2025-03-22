Replicate.client.api_token = ENV.fetch('REPLICATE_API_KEY')

class ReplicateWebhook
  def call(prediction)
    # do your thing
  end
end

ReplicateRails.configure do |config|
  config.webhook_adapter = ReplicateWebhook.new
end