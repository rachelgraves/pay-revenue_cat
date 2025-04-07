# frozen_string_literal: true

require "test_helper"

class Pay::RevenueCat::Webhooks::CancellationTest < ActiveSupport::TestCase
  def setup
    Pay::RevenueCat.integration_model_klass = "User"
    @pay_customer = pay_customers(:revenue_cat)
    @owner = @pay_customer.owner
  end

  test "iOS cancellation" do
    payload = initial_purchase_params
    subscription = create_subscription(payload)
    create_initial_charge(payload, subscription)

    assert_no_changes "Pay::RevenueCat::Charge.count" do
      Pay::RevenueCat::Webhooks::Cancellation.new.call(
        cancellation_params
      )
    end

    subscription.reload

    assert_equal "canceled", subscription.status
    assert_equal Time.at(1_740_141_539), subscription.ends_at
    assert_equal "UNSUBSCRIBE", subscription.data["cancel_reason"]
    assert_equal "APP_STORE", subscription.data["store"]
  end

  test "android cancellation" do
    payload = android_initial_purchase_params
    subscription = create_subscription(payload)
    create_initial_charge(payload, subscription)

    Pay::RevenueCat::Webhooks::Cancellation.new.call(
      android_cancellation_params
    )

    subscription.reload

    assert_equal 1, subscription.charges.count
    assert_equal "canceled", subscription.status
    assert_equal Time.at(1_740_571_667), subscription.ends_at
  end
end
