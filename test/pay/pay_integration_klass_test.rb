# frozen_string_literal: true

require "test_helper"

class Pay::PayIntegrationKlassTest < ActiveSupport::TestCase
  def setup
    ::Pay::RevenueCat.integration_model_klass = "Account"

    @pay_customer = pay_customers(:revenue_cat_account)
    @owner = @pay_customer.owner
  end

  test "INITIAL_PURCHASE -> webhook uses correct klass" do
    Pay::RevenueCat::Webhooks::Renewal.new.call(
      initial_purchase_params
    )

    assert_equal(
      accounts(:revenue_cat),
      Pay::RevenueCat::Subscription.sole.customer.owner
    )
  end

  test "RENEWAL -> webhook uses correct klass" do
    payload = initial_purchase_params
    subscription = create_subscription(payload)

    create_initial_charge(payload, subscription)

    Pay::RevenueCat::Webhooks::Renewal.new.call(
      renewal_params
    )

    subscription.reload

    assert_equal accounts(:revenue_cat), subscription.charges.last.customer.owner
  end

  test "CANCELLATION -> webhook uses correct klass" do
    payload = initial_purchase_params
    subscription = create_subscription(payload)

    create_initial_charge(payload, subscription)

    Pay::RevenueCat::Webhooks::Cancellation.new.call(
      cancellation_params
    )

    subscription.reload

    assert_equal "canceled", subscription.status
  end

  test "EXPIRATION -> webhook uses correct klass" do
    payload = initial_purchase_params
    subscription = create_subscription(payload)

    create_initial_charge(payload, subscription)

    Pay::RevenueCat::Webhooks::Expiration.new.call(
      expiration_params
    )

    subscription.reload

    assert_equal "canceled", subscription.status
  end
end
