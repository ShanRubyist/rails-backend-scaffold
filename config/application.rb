require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module RailsBackendScaffold
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true

    config.action_mailer.delivery_method = :smtp
    config.action_mailer.smtp_settings = {
      address: ENV['SMTP_ADDRESS'],
      port: ENV['SMTP_PORT'],
      domain: ENV['SMTP_DOMAIN'],
      user_name: ENV['SMTP_USERNAME'],
      password: ENV['SMTP_PASSWORD'],
      authentication: :login,
      enable_startttls_auto: ENV['SMTP_STARTTTLS_AUTO'],
      tls: ENV['SMTP_SSL'] == 'true' ? true : false
    }

    config.action_mailer.default_options = {
      from: "#{ENV['SITE_NAME']} <#{ENV['EMAIL_FROM']}>",
      reply_to: ENV['REPLY_TO']
    }
  end
end
