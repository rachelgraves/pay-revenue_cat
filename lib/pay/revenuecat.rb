# frozen_string_literal: true

require_relative "revenuecat/version"
require_relative "revenuecat/engine"

module Pay
  module Revenuecat
    class Error < StandardError; end

    module Webhooks
      autoload :InitialPurchase, "pay/revenuecat/webhooks/initial_purchase"
    end

    def self.enabled?
      true
    end
  end
end
