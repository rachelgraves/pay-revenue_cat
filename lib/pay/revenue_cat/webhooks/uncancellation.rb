# frozen_string_literal: true

module Pay
  module RevenueCat
    module Webhooks
      class Uncancellation
        def call(event)
          pay_subscription = Pay::RevenueCat::Subscription.find_by(
            processor_id: event["original_transaction_id"]
          )
          raise ActiveRecord::RecordNotFound, "RevenueCat subscription not found for transaction #{event["original_transaction_id"]}" if pay_subscription.nil?

          data = (pay_subscription.data || {}).except("cancel_reason", :cancel_reason)

          pay_subscription.with_lock do
            pay_subscription.update!(
              status: :active,
              ends_at: nil,
              data: data
            )
          end
        end
      end
    end
  end
end
