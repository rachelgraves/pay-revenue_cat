require "rails/engine"
require "action_dispatch"
require "rails/engine/configuration"

module Pay
  module Revenuecat
    class Engine < ::Rails::Engine
      engine_name "pay_revenuecat"
    end
  end
end
