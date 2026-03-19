module Pay
  module RevenueCat
    class Customer < Pay::Customer
      # has_many :charges, dependent: :destroy, class_name: "Pay::RevenueCat::Charge"
      has_many :subscriptions, dependent: :destroy, class_name: "Pay::RevenueCat::Subscription"
      # has_many :payment_methods, dependent: :destroy, class_name: "Pay::RevenueCat::PaymentMethod"
      # has_one :default_payment_method, -> { where(default: true) }, class_name: "Pay::RevenueCat::PaymentMethod"

      scope :revenue_cat, -> { where(processor: "revenue_cat") }

      def self.find_or_create_from_event(event)
        find_by(processor: :revenue_cat, processor_id: event["app_user_id"]) ||
          create_from_event(event)
      end

      def self.create_from_event(event)
        klass = Pay::RevenueCat.integration_model_klass.constantize
        field = Pay::RevenueCat.integration_model_field
        owner = klass.find_by!(field => event["app_user_id"])
        create!(owner: owner, processor: :revenue_cat, processor_id: event["app_user_id"], default: false)
      end

      def self.find_or_create_by_processor_id(processor_id)
        find_by(processor: :revenue_cat, processor_id: processor_id) ||
          begin
            klass = Pay::RevenueCat.integration_model_klass.constantize
            owner = klass.find_by(Pay::RevenueCat.integration_model_field => processor_id)
            return nil unless owner
            create!(owner: owner, processor: :revenue_cat, processor_id: processor_id, default: false)
          end
      end

      def transfer_to(target_customer)
        subscriptions.update_all(customer_id: target_customer.id)
        charges.update_all(customer_id: target_customer.id)
      end

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
