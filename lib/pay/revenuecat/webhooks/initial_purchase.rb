# frozen_string_literal: true

module Pay
  module Revenuecat
    module Webhooks
      class InitialPurchase
        def call(event)
          pay_customer = Pay::Customer.find_by!(
            processor: :revenuecat,
            processor_id: event["app_user_id"]
          )

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

          payment_processor = pay_customer.owner.payment_processor
          payment_processor.subscribe(**args)

          Pay::Revenuecat::Charge.create!(
            processor_id: event["transaction_id"],
            amount: event["price_in_purchased_currency"],
            metadata: event["metadata"],
            customer: pay_customer
          )
        end
      end
    end
  end
end
