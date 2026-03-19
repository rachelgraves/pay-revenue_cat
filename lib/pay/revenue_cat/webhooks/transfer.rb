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

              to_customer = Pay::RevenueCat::Customer.find_or_create_by_processor_id(to_id)
              unless to_customer
                Rails.logger.warn("RevenueCat TRANSFER: target owner not found for #{to_id}, skipping")
                next
              end

              from_customer.transfer_to(to_customer)
              Rails.logger.info("RevenueCat TRANSFER: moved subscriptions from #{from_id} to #{to_id}")
            end
          end
        end
      end
    end
  end
end
