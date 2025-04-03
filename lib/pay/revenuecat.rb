# frozen_string_literal: true

require_relative "revenuecat/version"
require_relative "revenuecat/engine"

module Pay
  module Revenuecat
    class Error < StandardError; end

    module Webhooks
      autoload :InitialPurchase, "pay/revenuecat/webhooks/initial_purchase"
      autoload :Renewal, "pay/revenuecat/webhooks/renewal"
    end

    def self.enabled?
      true
    end

    def self.configure_webhooks
      # https://docs.asaas.com/docs/webhook-para-cobrancas
      Pay::Webhooks.configure do |events|
        events.subscribe "revenuecat.INITIAL_PURCHASE", Pay::Revenuecat::Webhooks::InitialPurchase.new
      end
    end
  end
end
