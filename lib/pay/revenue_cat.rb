# frozen_string_literal: true

require_relative "revenue_cat/version"
require_relative "revenue_cat/engine"
require "pay/env"

module Pay
  module RevenueCat
    class Error < StandardError; end
    class InvalidEventSignature < Error; end

    module Webhooks
      autoload :Renewal, "pay/revenue_cat/webhooks/renewal"
      autoload :Cancellation, "pay/revenue_cat/webhooks/cancellation"
      autoload :Expiration, "pay/revenue_cat/webhooks/expiration"
    end

    def self.enabled?
      true
    end

    mattr_accessor :integration_model_klass
    @@integration_model_klass = "User"

    extend Pay::Env

    def self.webhook_access_key
      find_value_by_name(:revenue_cat, :webhook_access_key)
    end

    def self.configure_webhooks
      Pay::Webhooks.configure do |events|
        events.subscribe "revenue_cat.INITIAL_PURCHASE", Pay::RevenueCat::Webhooks::Renewal.new
        events.subscribe "revenue_cat.RENEWAL", Pay::RevenueCat::Webhooks::Renewal.new
        events.subscribe "revenue_cat.CANCELLATION", Pay::RevenueCat::Webhooks::Cancellation.new
        events.subscribe "revenue_cat.EXPIRATION", Pay::RevenueCat::Webhooks::Expiration.new
      end
    end
  end
end
