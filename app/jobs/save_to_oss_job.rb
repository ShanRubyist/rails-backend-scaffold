class SaveToOssJob < ApplicationJob
  queue_as :default

  def perform(ai_call, type = :generated_media, args)
    media = args.fetch(:io)

    io = case media
         when String
           require 'open-uri'
           URI.open(media)
         when Tempfile
           media
         end

    ai_call
      .send(type.to_sym)
      .attach(io: io, filename: args.fetch(:filename), content_type: args.fetch(:content_type))
  end
end