require "rails/engine"
require "action_dispatch"
require "rails/engine/configuration"

module Pay
  module RevenueCat
    class Engine < ::Rails::Engine
      engine_name "pay_revenue_cat"
      initializer "pay_revenue_cat.processors" do |app|
        if Pay.automount_routes
          app.routes.append do
            mount Pay::RevenueCat::Engine, at: Pay.routes_path
          end
        end
      end

      config.before_initialize do
        Pay::RevenueCat.configure_webhooks if Pay::RevenueCat.enabled?
      end
    end
  end
end
