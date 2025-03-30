module Api
  module V1
    class ScrapedInfosController < ApplicationController
      # GET /api/v1/scraped_infos/tdh
      def tdh
        @scraped_infos = ScrapedInfo.tdh_info
        render json: @scraped_infos
      end
      
      # GET /api/v1/scraped_infos/website
      def website
        @scraped_infos = ScrapedInfo.website_info
        render json: @scraped_infos
      end
      
      private
      
      def resource_class
        ScrapedInfo
      end
      
      def permitted_params
        [:source_type, :data, :tool_id]
      end
    end
  end
end 