require_relative '../../lib/scraper/tdh_info_scraper'

class ScrapeJob < ApplicationJob
  queue_as :default

  def perform(*args)
    urls = Tool.all.map(&:url)
    TDHScraper.scrape_urls(urls)
  end
end
