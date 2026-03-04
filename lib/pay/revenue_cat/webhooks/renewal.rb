# frozen_string_literal: true

module Pay
  module RevenueCat
    module Webhooks
      class Renewal
        def call(event)
          Rails.logger.tagged("Renewal") do
            pay_customer = Pay::Customer.find_by(
              processor: :revenue_cat,
              processor_id: event["app_user_id"]
            )

            Rails.logger.info("Customer: #{pay_customer.inspect}") if pay_customer

            if pay_customer.nil?
              klass = Pay::RevenueCat.integration_model_klass.constantize
              field = Pay::RevenueCat.integration_model_field
              owner = klass.find_by!(field => event["app_user_id"])
              pay_customer = Pay::RevenueCat::Customer.create!(
                owner: owner,
                processor: :revenue_cat,
                processor_id: event["app_user_id"],
                default: false
              )

              Rails.logger.info "Customer: #{pay_customer.inspect}"
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

            Rails.logger.info(args.inspect)

            Rails.logger.info "Finding subscription by original_transaction_id=#{event["original_transaction_id"]}"

            pay_subscription = pay_customer.subscriptions.find_by(
              processor_id: event["original_transaction_id"]
            )

            if pay_subscription.nil?
              Rails.logger.info "No existing subscription found, creating"
              pay_subscription = pay_customer.subscribe(**args)
            else
              Rails.logger.info pay_subscription.inspect
              # locked because that's what the Pay gem folks do
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
end
