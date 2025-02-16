require 'faraday'

module Turnstile
  extend ActiveSupport::Concern

  included do |base|
  end

  module ClassMethods
  end

  def cf_validation(token, remote_ip=nil)
    sec_key = ENV.fetch('CLOUDFLARE_TURNSTILE_SECRET_KEY')
    # sec_key = '1x0000000000000000000000000000000AA'

    client = Faraday.new(url: "https://challenges.cloudflare.com")
    resp = client.post('/turnstile/v0/siteverify') do |req|
      req.headers['Content-Type'] = 'application/json'
      req.body = {
        secret: sec_key,
        response: token,
        remoteip: remote_ip
      }.to_json
    end

    data = JSON.parse(resp.body)
    puts resp.body

    if (data.fetch('success'))
      true
    else
      fail 'CloudFlare Turnstile failed'
    end
  end
end