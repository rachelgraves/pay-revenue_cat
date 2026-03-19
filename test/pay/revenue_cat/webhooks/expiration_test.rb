# frozen_string_literal: true

require "test_helper"

class Pay::RevenueCat::Webhooks::ExpirationTest < ActiveSupport::TestCase
  def setup
    Pay::RevenueCat.integration_model_klass = "User"

    @pay_customer = pay_customers(:revenue_cat)
    @owner = @pay_customer.owner
  end

  test "iOS expiration" do
    payload = initial_purchase_params
    subscription = create_subscription(payload)
    create_initial_charge(payload, subscription)
    assert_equal "APP_STORE", subscription.data["store"]

    Pay::RevenueCat::Webhooks::Expiration.new.call(
      expiration_params
    )

    subscription.reload

    assert_equal "canceled", subscription.status
    assert_equal Time.at(1_740_141_539), subscription.ends_at
    assert_equal "APP_STORE", subscription.data["store"]
    assert_equal "UNSUBSCRIBE", subscription.data["expiration_reason"]
  end

  test "android expiration" do
    payload = android_initial_purchase_params
    subscription = create_subscription(payload)
    create_initial_charge(payload, subscription)

    Pay::RevenueCat::Webhooks::Expiration.new.call(
      android_expiration_params
    )

    subscription.reload

    assert_equal 1, subscription.charges.count
    assert_equal "canceled", subscription.status
    assert_equal Time.at(1_740_571_667), subscription.ends_at
  end

  test "runs within a transaction" do
    payload = initial_purchase_params
    subscription = create_subscription(payload)
    create_initial_charge(payload, subscription)
    original_status = subscription.status
    original_data = subscription.data.dup

    Pay::RevenueCat::Subscription.any_instance.stubs(:update!).raises(ActiveRecord::RecordInvalid)

    assert_raises ActiveRecord::RecordInvalid do
      Pay::RevenueCat::Webhooks::Expiration.new.call(expiration_params)
    end

    subscription.reload
    assert_equal original_status, subscription.status
    assert_equal original_data, subscription.data
  end
end
