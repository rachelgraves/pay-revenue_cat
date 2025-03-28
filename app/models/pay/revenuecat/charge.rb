module Pay
  module Revenuecat
    class Charge < Pay::Charge
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
