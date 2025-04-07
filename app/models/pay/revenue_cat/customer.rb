module Pay
  module RevenueCat
    class Customer < Pay::Customer
      # has_many :charges, dependent: :destroy, class_name: "Pay::RevenueCat::Charge"
      has_many :subscriptions, dependent: :destroy, class_name: "Pay::RevenueCat::Subscription"
      # has_many :payment_methods, dependent: :destroy, class_name: "Pay::RevenueCat::PaymentMethod"
      # has_one :default_payment_method, -> { where(default: true) }, class_name: "Pay::RevenueCat::PaymentMethod"

      scope :revenuecat, -> { where(processor: "revenuecat") }

      def update_api_record(**_attributes)
        self
      end

      def subscribe(
        name: Pay.default_product_name,
        plan: Pay.default_plan_name,
        **options
      )
        attributes = options.merge(
          name: name,
          processor_plan: plan,
          status: :active,
          quantity: options.fetch(:quantity, 1)
        )

        subscriptions.create!(attributes)
      end
    end
  end
end
