# frozen_string_literal: true

module Pay
  module Revenuecat
    module Webhooks
      class Cancellation
        def call(event)
          pay_subscription = Pay::Subscription.find_by_processor_and_id(
            :revenuecat, event["original_transaction_id"]
          )

          ends_at = Time.at(event["expiration_at_ms"].to_i / 1000)

          pay_subscription.with_lock do # I added a lock here, donno why they didn't have one
            pay_subscription.update!(
              status: (ends_at.future? ? :active : :canceled), # TODO: hmm so this means we need to change it to cancelled on the day?
              trial_ends_at: (ends_at if pay_subscription.trial_ends_at?),
              ends_at: ends_at
              # TODO: add cancellation reason? from https://www.revenuecat.com/docs/integrations/webhooks/event-types-and-fields#cancellation-and-expiration-reasons
            )
          end
        end
      end
    end
  end
end
