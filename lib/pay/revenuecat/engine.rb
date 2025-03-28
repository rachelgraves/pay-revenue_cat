require "rails/engine"

module Pay
  module Revenuecat
    class Engine < ::Rails::Engine
      engine_name "pay_revenuecat"

      initializer "pay_revenuecat.routes" do |app|
        if Pay.automount_routes
          app.routes.append do
            mount Pay::Revenuecat::Engine, at: Pay.routes_path
          end
        end
      end

      config.to_prepare do
        Pay::Revenuecat.setup if Pay::Revenuecat.enabled?
      end
    end
  end
end
