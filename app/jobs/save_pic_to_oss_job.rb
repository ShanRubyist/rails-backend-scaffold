class SavePicToOssJob < ApplicationJob
  queue_as :default

  def perform(args)
    image = save_to_db(args)
    require 'open-uri'

    # TODO: replicated_calls 表需要重构
    user
      .replicated_calls
      .find_by(predict_id: predict_id)
      .image
      .attach(io: URI.open(image), filename: URI(image).path.split('/').last) unless image.empty?
  end
end
