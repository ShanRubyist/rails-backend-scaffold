require 'nokogiri'
require 'open-uri'
require 'json'

class Scraper
  def self.scrape(url)
    html = URI.open(url,
                    'User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36')

    doc = Nokogiri::HTML(html)

    format_data(doc, url)
  end

  def self.scrape_urls(urls, &block)
    puts "[*]Scraping #{urls.length} urls"

    index = 1
    urls.map do |url|
      puts "[*]Scraping (#{index}/#{urls.length}): #{url}"
      index += 1
      self.scrape(url, &block)
    end
  end
end