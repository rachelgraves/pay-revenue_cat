# frozen_string_literal: true

module Pay
  module RevenueCat
    module Webhooks
      class Transfer
        def call(event)
          transferred_from = Array(event["transferred_from"])
          transferred_to = Array(event["transferred_to"])

          transferred_from.each_with_index do |from_id, index|
            to_id = transferred_to[index]
            next unless to_id

            ActiveRecord::Base.transaction do
              from_customer = Pay::RevenueCat::Customer.find_by(processor: :revenue_cat, processor_id: from_id)
              unless from_customer
                Rails.logger.warn("RevenueCat TRANSFER: source customer not found for #{from_id}, skipping")
                next
              end

              to_customer = Pay::RevenueCat::Customer.find_by(processor: :revenue_cat, processor_id: to_id)
              if to_customer.nil?
                klass = Pay::RevenueCat.integration_model_klass.constantize
                owner = klass.find_by(Pay::RevenueCat.integration_model_field => to_id)
                unless owner
                  Rails.logger.warn("RevenueCat TRANSFER: target owner not found for #{to_id}, skipping")
                  next
                end
                to_customer = Pay::RevenueCat::Customer.create!(
                  owner: owner, processor: :revenue_cat, processor_id: to_id, default: false
                )
              end

              from_customer.subscriptions.update_all(customer_id: to_customer.id)
              from_customer.charges.update_all(customer_id: to_customer.id)
              Rails.logger.info("RevenueCat TRANSFER: moved subscriptions from #{from_id} to #{to_id}")
            end
          end
        end
      end
    end
  end
end
