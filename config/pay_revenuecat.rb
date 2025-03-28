# frozen_string_literal: true

require "bootsnap/setup"

require "rails"
require "action_controller/railtie"
require "action_view/railtie"

class App < Rails::Application
  config.eager_load = false
  config.hosts.clear
  config.autoload_paths << "#{root}/app/controllers"
  config.secret_key_base = "secret-key"
  config.action_dispatch.show_exceptions = :rescuable
  config.active_support.to_time_preserves_timezone = :zone
  config.action_controller.perform_caching = true
end

App.initialize!
