module Api
  module V1
    class TagsController < ApplicationController
      def index
        render json: Tag.all.map do |tag|
          {
            id: tag.id,
            name: tag.name,
            slug: tag.slug
          }
        end
      end

      # GET /api/v1/tags/1/tools
      def tools
        @tag = Tag.find(params[:id])
        @tools = @tag.tools.published
        render json: @tools
      end

      private

      def resource_class
        Tag
      end

      def permitted_params
        [:name, :description]
      end
    end
  end
end 