# frozen_string_literal: true

require_relative "revenuecat/version"
require_relative "revenuecat/engine"

module Pay
  module Revenuecat
    class Error < StandardError; end

    module Webhooks
      autoload :InitialPurchase, "pay/revenuecat/webhooks/initial_purchase"
      autoload :Renewal, "pay/revenuecat/webhooks/renewal"
      autoload :Cancellation, "pay/revenuecat/webhooks/cancellation"
      autoload :Expiration, "pay/revenuecat/webhooks/expiration"
    end

    def self.enabled?
      true
    end

    mattr_accessor :integration_model_klass
    @@integration_model_klass = "User"

    def self.configure_webhooks
      Pay::Webhooks.configure do |events|
        events.subscribe "revenuecat.INITIAL_PURCHASE", Pay::Revenuecat::Webhooks::Renewal.new
        events.subscribe "revenuecat.RENEWAL", Pay::Revenuecat::Webhooks::Renewal.new
        events.subscribe "revenuecat.CANCELLATION", Pay::Revenuecat::Webhooks::Cancellation.new
        events.subscribe "revenuecat.EXPIRATION", Pay::Revenuecat::Webhooks::Expiration.new
      end
    end
  end
end
