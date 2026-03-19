# frozen_string_literal: true

module Pay
  module RevenueCat
    module Webhooks
      class Renewal
        def call(event)
          pay_customer = Pay::RevenueCat::Customer.find_or_create_from_event(event)
          pay_subscription = Pay::RevenueCat::Subscription.find_or_create_from_event(pay_customer, event)

          Pay::RevenueCat::Charge.create!(
            processor_id: event["transaction_id"],
            amount: (event["price_in_purchased_currency"] * 100).to_i,
            metadata: event["metadata"],
            customer: pay_customer,
            subscription: pay_subscription
          )
        end
      end
    end
  end
end
