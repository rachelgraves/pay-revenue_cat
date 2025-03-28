# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"

require "rails"
require "action_controller/railtie"
require "pay/revenuecat"
require "minitest/autorun"

class App < Rails::Application
  config.eager_load = false
  config.secret_key_base = "secret"
  config.hosts.clear
  config.root = File.expand_path("..", __dir__)

  routes.append do
    mount Pay::Revenuecat::Engine => "/pay-revenuecat"
  end
end

Rails.application = App.instance
Rails.backtrace_cleaner.remove_silencers!
App.initialize!

require "rails/test_help"
