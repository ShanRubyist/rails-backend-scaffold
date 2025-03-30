module Api
  module V1
    class ToolsController < ApplicationController

      def index
        published
      end

      def search
        published
      end

      def show
        @tool = Tool.published.find_by(name: params[:id])
        if @tool
          render json:
                   formatted_tool_json(@tool)
                     .merge({
                              addedDate: @tool.created_at,
                              logo: @tool.logo_url,
                              monthlyTraffic: @tool.popularity,
                              pricing_type: @tool.pricing_type,
                              rating: 3.5,
                              reviews: 2,
                              collections: 3,
                              linkedin: true,
                              github: true,
                              screenshot: '',
                            })
        else
          render json: {
            message: 'tool not found'
          }
        end
      end

      def tool_alternatives
        @tool = Tool.published.find_by(name: params[:name])

        if @tool
          render json: (
            @tool.alternatives.map do |alt|
              formatted_tool_json(alt)
            end
          )
        else
          render json: {
            message: 'tool not found'
          }
        end
      end

      # GET /api/v1/tools/published
      def published
        params[:page] ||= 1
        params[:per] ||= 20

        @tools = Tool.published
        @tools = @tools.search_by_query(params[:query]) if params[:query]
        @tools = @tools.search_by_tags(params[:tags]) if params[:tags]
        @tools = @tools.order_by(params[:sort_by]) if params[:sort_by]
        @tools = @tools.page(params[:page].to_i).per(params[:per].to_i)

        render json: {
          total: @tools.total_count,
          current_page: @tools.current_page,
          total_pages: @tools.total_pages,
          tools: (
            @tools.map do |tool|
              formatted_tool_json(tool)
            end
          )
        }
      end

      # GET /api/v1/tools/unpublished
      def unpublished
        @tools = Tool.unpublished
        render json: @tools
      end

      # POST /api/v1/tools/1/publish
      def publish
        @tool = Tool.find(params[:id])
        @tool.update(published: true)
        render json: @tool
      end

      # POST /api/v1/tools/1/unpublish
      def unpublish
        @tool = Tool.find(params[:id])
        @tool.update(published: false)
        render json: @tool
      end

      def tag_tools
        params[:page] ||= 1
        params[:per] ||= 20

        tag = Tag.find_by(slug: params[:tag])
        if tag
          @tools = tag.tools
          @tools = @tools.order_by(params[:sort_by]) if params[:sort_by]
          @tools = @tools.page(params[:page].to_i).per(params[:per].to_i)

          render json: {
            total: @tools.total_count,
            current_page: @tools.current_page,
            total_pages: @tools.total_pages,
            tools: (
              @tools.map do |tool|
                formatted_tool_json(tool)
              end
            )
          }
        else
          render json: {
            message: 'tag not found'
          }
        end
      end

      def monthly_tools
        params[:page] ||= 1
        params[:per] ||= 20

        date = Date.strptime(params[:month], "%Y-%m")

        if date
          @tools = Tool.monthly_tools(date)
          @tools = @tools.order_by(params[:sort_by]) if params[:sort_by]
          @tools = @tools.page(params[:page].to_i).per(params[:per].to_i)

          render json: {
            total: @tools.total_count,
            current_page: @tools.current_page,
            total_pages: @tools.total_pages,
            tools: (
              @tools.map do |tool|
                formatted_tool_json(tool)
              end
            )
          }
        else
          render json: {
            message: 'date invalid'
          }
        end
      end

      private

      def formatted_tool_json(tool)
        {
          id: tool.id,
          name: tool.name,
          url: url_with_utm(tool.url),
          logo: '',
          description: tool.description,
          tags: tool.tags.map(&:name),
          # likes: 13500,
          # growth: 27.52,
          # featured: false
        }

      end

      def url_with_utm(url)
        url += "?utm_source=#{ENV.fetch('HOST').sub('api.', '')}"
        url += "&utm_medium=referral&utm_campaign=navigation"
        url
      end

      def resource_class
        Tool
      end

      def permitted_params
        [:name, :description, :url, :logo_url, :published, :popularity, :pricing_type, tag_ids: []]
      end
    end
  end
end 