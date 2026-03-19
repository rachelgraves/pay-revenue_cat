# frozen_string_literal: true

require "test_helper"

class Pay::RevenueCat::Webhooks::ExpirationTest < ActiveSupport::TestCase
  def setup
    Pay::RevenueCat.integration_model_klass = "User"
    @pay_customer = pay_customers(:revenue_cat)
    @owner = @pay_customer.owner
  end

  test "expires subscription and stores expiration_reason" do
    payload = initial_purchase_params
    subscription = create_subscription(payload)
    create_initial_charge(payload, subscription)

    Pay::RevenueCat::Webhooks::Expiration.new.call(expiration_params)

    subscription.reload
    assert_equal "canceled", subscription.status
    assert_equal "UNSUBSCRIBE", subscription.data["expiration_reason"]
  end

  test "raises when subscription not found" do
    assert_raises ActiveRecord::RecordNotFound do
      Pay::RevenueCat::Webhooks::Expiration.new.call(expiration_params)
    end
  end

  test "runs within a transaction" do
    payload = initial_purchase_params
    subscription = create_subscription(payload)
    create_initial_charge(payload, subscription)

    Pay::RevenueCat::Subscription.any_instance.stubs(:update!).raises(ActiveRecord::RecordInvalid)

    assert_raises ActiveRecord::RecordInvalid do
      Pay::RevenueCat::Webhooks::Expiration.new.call(expiration_params)
    end
  end
end
