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
            processor_id: event["original_transaction_id"], # seems to be the closest thing I can find to a subscription id across all events
            current_period_start: Time.at(event["purchased_at_ms"].to_i / 1000),
            current_period_end: Time.at(event["expiration_at_ms"].to_i / 1000),
            ends_at: Time.at(event["expiration_at_ms"].to_i / 1000),
            metadata: event["metadata"],
            data: data,
            metered: false, # TODO: Handle metered billing
            status: :active # TODO: set "on_trial", "active", "canceled"
            # application_fee_percent: nil,
            # application_fee_percent: — stripe send this, though is null in all fixtures, revenue cat send:
            #  "tax_percentage"=>0.1705,
            #  "commission_percentage"=>0.2489,
            # "is_trial_conversion"=>false, # TODO: do something with this?
          }

          payment_processor = pay_customer.owner.payment_processor
          payment_processor.subscribe(**args) # TODO: with lock?

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
