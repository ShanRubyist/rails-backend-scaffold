require_relative '../scraper'

class TDHScraper < Scraper
  class << self
    def format_data(doc, url)
      scraped_data =
        {
          title: extract_title(doc),
          description: extract_description(doc),
          h1: extract_h1(doc),
          body: extract_body(doc),
          url: url
        }

      # 保存或更新数据到数据库
      save_to_database(scraped_data)

      scraped_data
    end

    private

    def save_to_database(data)
      tool = Tool.find_by(url: data[:url])

      # 查找或创建新记录
      scraped_info = ScrapedInfo.find_or_initialize_by(
        source_type: 'tdh',
        tool_id: tool.id
      )

      # 更新数据
      scraped_info.data = data
      scraped_info.last_scraped_at = Time.current
      scraped_info.tool = tool if tool
      scraped_info.save!

      tool.update(description: data[:description])
    end

    def extract_title(doc)
      doc.at_css('title')&.text&.strip
    end

    def extract_description(doc)
      doc.at_css('meta[name="description"]')&.[]('content')&.strip
    end

    def extract_h1(doc)
      doc.at_css('h1')&.text&.strip
    end

    def extract_body(doc)
      doc.at_css('body')&.text&.strip
    end
  end
end