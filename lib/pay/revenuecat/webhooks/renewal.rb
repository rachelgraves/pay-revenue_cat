# frozen_string_literal: true

module Pay
  module Revenuecat
    module Webhooks
      class Renewal
        def call(event)
          klass = Pay::Revenuecat.integration_model_klass.constantize

          pay_customer = klass.find(
            event["app_user_id"]
          ).payment_processor

          if pay_customer.processor_id.blank?
            pay_customer.update!(
              processor_id: event["original_app_user_id"]
            )
          end

          data = {
            store: event["store"]
          }

          args = {
            name: event["presented_offering_id"],
            plan: event["product_id"],
            processor_id: event["original_transaction_id"],
            current_period_start: Time.at(event["purchased_at_ms"].to_i / 1000),
            current_period_end: Time.at(event["expiration_at_ms"].to_i / 1000),
            ends_at: Time.at(event["expiration_at_ms"].to_i / 1000),
            metadata: event["metadata"],
            data: data,
            metered: false,
            status: :active
          }

          if pay_customer.subscriptions.empty?
            pay_subscription = pay_customer.subscribe(**args)
          else
            pay_subscription = Pay::Subscription.find_by_processor_and_id(
              :revenuecat,
              event["original_transaction_id"]
            )

            # locked because that's that the Pay gem folks do
            pay_subscription.with_lock do
              pay_subscription.update!(
                **args.slice(
                  :status,
                  :ends_at,
                  :current_period_start,
                  :current_period_end
                )
              )
            end
          end

          Pay::Revenuecat::Charge.create!(
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
