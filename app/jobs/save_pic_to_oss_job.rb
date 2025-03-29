class SavePicToOssJob < ApplicationJob
  queue_as :default

  def perform(ai_call, type=:generated_media, args)
    require 'open-uri'

    ai_call
      .find_by(id: id)
      .call(type.to_sym)
      .attach(io: URI.open(image), filename: URI(image).path.split('/').last) unless image.empty?
  end
end
