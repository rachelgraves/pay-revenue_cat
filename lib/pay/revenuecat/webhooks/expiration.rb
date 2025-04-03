# frozen_string_literal: true

module Pay
  module Revenuecat
    module Webhooks
      class Expiration
        def call(event)
          pay_subscription = Pay::Subscription.find_by_processor_and_id(
            :revenuecat, event["original_transaction_id"]
          )

          ends_at = Time.at(event["expiration_at_ms"].to_i / 1000)

          pay_subscription.with_lock do # I added a lock here, donno why they didn't have one
            pay_subscription.update!(
              status: "canceled",
              ends_at: ends_at
              # TODO: add an expiration reason?
            )
          end
        end
      end
    end
  end
end
