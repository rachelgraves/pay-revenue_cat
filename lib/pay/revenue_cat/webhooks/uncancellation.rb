# frozen_string_literal: true

module Pay
  module RevenueCat
    module Webhooks
      class Uncancellation
        def call(event)
          ActiveRecord::Base.transaction do
            pay_subscription = Pay::RevenueCat::Subscription.find_by(
              processor_id: event["original_transaction_id"]
            )

            if pay_subscription.nil?
              customer = Pay::RevenueCat::Customer.find_or_create_from_event(event)
              pay_subscription = customer.subscribe(
                **Pay::RevenueCat::Subscription.subscription_attributes(event)
              )
            end

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
end
