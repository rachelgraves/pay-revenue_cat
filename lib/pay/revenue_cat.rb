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
      autoload :Transfer, "pay/revenue_cat/webhooks/transfer"
      autoload :Uncancellation, "pay/revenue_cat/webhooks/uncancellation"
    end

    def self.enabled?
      true
    end

    mattr_accessor :integration_model_klass
    @@integration_model_klass = "User"

    mattr_accessor :integration_model_field
    @@integration_model_field = :id

    mattr_writer :allow_sandbox
    @@allow_sandbox = false

    def self.allow_sandbox?(event = nil)
      if @@allow_sandbox.respond_to?(:call)
        @@allow_sandbox.call(event)
      else
        @@allow_sandbox
      end
    end

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
        events.subscribe "revenue_cat.TRANSFER", Pay::RevenueCat::Webhooks::Transfer.new
        events.subscribe "revenue_cat.UNCANCELLATION", Pay::RevenueCat::Webhooks::Uncancellation.new
      end
    end
  end
end
