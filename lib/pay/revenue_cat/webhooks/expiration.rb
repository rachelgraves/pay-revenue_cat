# frozen_string_literal: true

module Pay
  module RevenueCat
    module Webhooks
      class Expiration
        def call(event)
          pay_subscription = Pay::Subscription.find_by_processor_and_id(
            :revenue_cat, event["original_transaction_id"]
          )

          data = (pay_subscription.data || {}).merge(
            {
              expiration_reason: event["expiration_reason"]
            }
          )

          ends_at = Time.at(event["expiration_at_ms"].to_i / 1000)

          pay_subscription.with_lock do
            pay_subscription.update!(
              status: "canceled",
              ends_at: ends_at,
              data: data
            )
          end
        end
      end
    end
  end
end
