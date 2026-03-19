# frozen_string_literal: true

module Pay
  module RevenueCat
    module Webhooks
      class Renewal
        def call(event)
          customer = Pay::RevenueCat::Customer.find_or_create_from_event(event)
          subscription = Pay::RevenueCat::Subscription.find_or_create_from_event(customer, event)
          Pay::RevenueCat::Charge.create_from_event(customer, subscription, event)
        end
      end
    end
  end
end
