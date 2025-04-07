# frozen_string_literal: true

require "test_helper"

class Pay::Revenuecat::Webhooks::RenewalTest < ActiveSupport::TestCase
  def setup
    Pay::Revenuecat.integration_model_klass = "User"
    @pay_customer = pay_customers(:revenuecat)
    @owner = @pay_customer.owner
  end

  test "INITIAL_PURCHASE -> no customer exists -> sets the payment processor to revenuecat" do
    @pay_customer.destroy

    assert_changes -> { Pay::Revenuecat::Customer.count } do
      Pay::Revenuecat::Webhooks::Renewal.new.call(
        initial_purchase_params
      )
    end

    @owner.reload

    assert_equal(
      @owner.id,
      @owner.payment_processor.processor_id.to_i
    )
  end

  test "INITIAL_PURCHASE -> customer exists -> subscribes the customer" do
    assert_difference "Pay::Charge.count" do
      Pay::Revenuecat::Webhooks::Renewal.new.call(
        initial_purchase_params
      )
    end

    subscription = @pay_customer.reload.subscriptions.sole
    charge = subscription.charges.sole

    assert_equal(
      initial_purchase_params["presented_offering_id"],
      subscription.name
    )
    assert_equal(
      initial_purchase_params["product_id"],
      subscription.processor_plan
    )
    assert_equal(
      initial_purchase_params["metadata"],
      subscription.metadata
    )
    assert_equal(
      initial_purchase_params["store"],
      subscription.data["store"]
    )
    assert_equal(
      Time.at(initial_purchase_params["expiration_at_ms"] / 1000),
      subscription.ends_at
    )
    assert_equal(
      subscription, charge.subscription
    )
  end

  test "RENEWAL -> iOS -> updates subscription attributes" do
    payload = initial_purchase_params
    subscription = create_subscription(payload)
    create_initial_charge(payload, subscription)

    Pay::Revenuecat::Webhooks::Renewal.new.call(
      renewal_params
    )

    subscription.reload

    assert_equal(
      Time.at(renewal_params["expiration_at_ms"] / 1000),
      subscription.current_period_end
    )

    assert_equal(
      Time.at(renewal_params["expiration_at_ms"] / 1000),
      subscription.ends_at
    )
    assert_equal(
      subscription, Pay::Revenuecat::Charge.last.subscription
    )
  end

  test "RENEWAL -> iOS -> adds a new charge to the customer" do
    payload = initial_purchase_params
    subscription = create_subscription(payload)
    create_initial_charge(payload, subscription)

    assert_difference -> { @pay_customer.reload.charges.count } do
      Pay::Revenuecat::Webhooks::Renewal.new.call(
        renewal_params
      )
    end

    charge = @pay_customer.charges.last
    assert_equal renewal_params["transaction_id"], charge.processor_id
    assert_equal 599, charge.amount
  end

  test "RENEWAL -> iOS -> reactivates a cancelled subscription" do
    payload = initial_purchase_params
    subscription = create_subscription(payload)
    create_initial_charge(payload, subscription)

    subscription.update!(status: :cancelled, ends_at: 1.day.ago)

    Pay::Revenuecat::Webhooks::Renewal.new.call(
      renewal_after_cancellation_params
    )

    subscription.reload
    assert_equal "active", subscription.status
    assert_equal Time.at(1_740_658_577), subscription.ends_at
    assert_equal Time.at(1_740_658_577), subscription.current_period_end
  end

  # we may not get here in real life but what happens with sandbox accounts
  # is if you have already had a subscriotion expire and start a new one
  # revenuecat send a renewal event. If you're re-seeding your database this
  # can be very annoying.
  test "RENEWAL -> iOS -> creates a new subscription if one does not exist" do
    assert_difference "Pay::Revenuecat::Subscription.count" do
      Pay::Revenuecat::Webhooks::Renewal.new.call(
        renewal_after_cancellation_params
      )
    end

    subscription = Pay::Revenuecat::Subscription.last

    assert_equal "active", subscription.status
    assert_equal Time.at(1_740_658_577), subscription.ends_at
    assert_equal Time.at(1_740_658_577), subscription.current_period_end
  end

  test "RENEWAL -> Android -> adds a charge" do
    payload = android_initial_purchase_params
    subscription = create_subscription(payload)
    create_initial_charge(payload, subscription)

    assert_difference "Pay::Charge.count" do
      Pay::Revenuecat::Webhooks::Renewal.new.call(
        renewal_android_params
      )
    end
  end
end
