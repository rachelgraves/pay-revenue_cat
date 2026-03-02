module Pay
  module RevenueCat
    class Subscription < Pay::Subscription
      def paused? = status == "paused"

      def resumable? = false
    end
  end
end
