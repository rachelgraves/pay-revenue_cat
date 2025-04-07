module Pay
  module RevenueCat
    class Subscription < Pay::Subscription
      # def paused?
      #   status == "paused"
      # end
      #
      # def pause
      #   update(status: :paused, trial_ends_at: Time.current)
      # end
      def resumable? = false
    end
  end
end
