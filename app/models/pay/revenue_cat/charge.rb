module Pay
  module RevenueCat
    class Charge < Pay::Charge
      def self.create_from_event(customer, subscription, event)
        create!(
          processor_id: event["transaction_id"],
          amount: (event["price_in_purchased_currency"] * 100).to_i,
          metadata: event["metadata"],
          customer: customer,
          subscription: subscription
        )
      end

      def api_record
        # stripe uses this to call the Stripe client and get the latest charge details
        # but we just get the information from the webhook
        self
      end

      def refund!(amount_to_refund = nil)
        # TODO: investigate if we can trigger a refund ourselves?
      end
    end
  end
end
