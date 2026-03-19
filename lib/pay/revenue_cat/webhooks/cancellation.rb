# frozen_string_literal: true

module Pay
  module RevenueCat
    module Webhooks
      class Cancellation
        def call(event)
          pay_subscription = Pay::RevenueCat::Subscription.find_by(
            processor_id: event["original_transaction_id"]
          )
          raise ActiveRecord::RecordNotFound, "RevenueCat subscription not found for transaction #{event["original_transaction_id"]}" if pay_subscription.nil?

          data = (pay_subscription.data || {}).merge(
            {
              cancel_reason: event["cancel_reason"]
            }
          )

          ends_at = Time.at(event["expiration_at_ms"].to_i / 1000)

          pay_subscription.with_lock do
            pay_subscription.update!(
              status: (ends_at.future? ? :active : :canceled),
              ends_at: ends_at,
              data: data
            )
          end
        end
      end
    end
  end
end
