require "rails/engine"
require "action_dispatch"
require "rails/engine/configuration"

module Pay
  module Revenuecat
    class Engine < ::Rails::Engine
      engine_name "pay_revenuecat"
      initializer "pay_revenuecat.processors" do |app|
        if Pay.automount_routes
          app.routes.append do
            mount Pay::Revenuecat::Engine, at: Pay.routes_path
          end
        end
      end

      # config.before_initialize do
      #   Pay::Revenuecat.configure_webhooks if Pay::Revenuecat.enabled?
      # end
    end
  end
end
