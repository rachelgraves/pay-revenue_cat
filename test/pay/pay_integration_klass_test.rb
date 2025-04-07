# frozen_string_literal: true

require "test_helper"

class Pay::PayIntegrationKlassTest < ActiveSupport::TestCase
  def setup
    ::Pay::Revenuecat.integration_model_klass = "Account"

    @pay_customer = pay_customers(:revenuecat_account)
    @owner = @pay_customer.owner
  end

  test "INITIAL_PURCHASE -> webhook uses correct klass" do
    Pay::Revenuecat::Webhooks::Renewal.new.call(
      initial_purchase_params
    )

    assert_equal(
      accounts(:revenuecat),
      Pay::Revenuecat::Subscription.sole.customer.owner
    )
  end

  test "RENEWAL -> webhook uses correct klass" do
    payload = initial_purchase_params
    subscription = create_subscription(payload)

    create_initial_charge(payload, subscription)

    Pay::Revenuecat::Webhooks::Renewal.new.call(
      renewal_params
    )

    subscription.reload

    assert_equal accounts(:revenuecat), subscription.charges.last.customer.owner
  end

  test "CANCELLATION -> webhook uses correct klass" do
    payload = initial_purchase_params
    subscription = create_subscription(payload)

    create_initial_charge(payload, subscription)

    Pay::Revenuecat::Webhooks::Cancellation.new.call(
      cancellation_params
    )

    subscription.reload

    assert_equal "canceled", subscription.status
  end

  test "EXPIRATION -> webhook uses correct klass" do
    payload = initial_purchase_params
    subscription = create_subscription(payload)

    create_initial_charge(payload, subscription)

    Pay::Revenuecat::Webhooks::Expiration.new.call(
      expiration_params
    )

    subscription.reload

    assert_equal "canceled", subscription.status
  end
end
