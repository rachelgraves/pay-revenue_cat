module Pay
  module RevenueCat
    class Subscription < Pay::Subscription
      def active? = !ends_at? || ends_at.future?

      def canceled? = status == "canceled"

      def paused? = status == "paused"

      def resumable? = false

      def self.find_or_create_from_event(customer, event)
        existing = customer.subscriptions.find_by(processor_id: event["original_transaction_id"])
        if existing
          existing.with_lock do
            data = (existing.data || {}).except("cancel_reason", :cancel_reason)
            existing.update!(**renewal_attributes(event), data: data)
          end
          existing
        else
          customer.subscribe(**subscription_attributes(event))
        end
      end

      def self.subscription_attributes(event)
        {
          name: event["presented_offering_id"],
          plan: event["product_id"],
          processor_id: event["original_transaction_id"],
          current_period_start: Time.at(event["purchased_at_ms"].to_i / 1000),
          current_period_end: Time.at(event["expiration_at_ms"].to_i / 1000),
          ends_at: Time.at(event["expiration_at_ms"].to_i / 1000),
          metadata: event["metadata"],
          data: {store: event["store"]},
          metered: false,
          status: :active
        }
      end

      def self.renewal_attributes(event)
        subscription_attributes(event).slice(:status, :ends_at, :current_period_start, :current_period_end)
      end
    end
  end
end
