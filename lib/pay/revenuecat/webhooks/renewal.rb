# frozen_string_literal: true

module Pay
  module Revenuecat
    module Webhooks
      class Renewal
        def call(event)
          pay_subscription = Pay::Subscription.find_by_processor_and_id(
            :revenuecat, event["original_transaction_id"]
          )

          args = {
            current_period_start: Time.at(event["purchased_at_ms"].to_i / 1000),
            current_period_end: Time.at(event["expiration_at_ms"].to_i / 1000),
            status: :active,
            ends_at: Time.at(event["expiration_at_ms"].to_i / 1000)
          }

          # locked because that's that the Pay gem folks do
          pay_subscription.with_lock { pay_subscription.update!(**args) }

          Pay::Revenuecat::Charge.create!(
            processor_id: event["transaction_id"],
            amount: (event["price_in_purchased_currency"] * 100).to_i,
            metadata: event["metadata"],
            customer: Pay::Customer.find_by(
              type: "Pay::Revenuecat::Customer",
              processor_id: event["app_user_id"]
            )
          )
        end
      end
    end
  end
end
