# This file is used by Rack-based servers to start the application.
require 'logger'
require_relative "config/environment"

run Rails.application
Rails.application.load_server
