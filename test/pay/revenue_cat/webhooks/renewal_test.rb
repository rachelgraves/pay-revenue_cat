# frozen_string_literal: true

require "test_helper"

class Pay::RevenueCat::Webhooks::RenewalTest < ActiveSupport::TestCase
  def setup
    Pay::RevenueCat.integration_model_klass = "User"
    @pay_customer = pay_customers(:revenue_cat)
    @owner = @pay_customer.owner
  end

  def teardown
    Pay::RevenueCat.integration_model_field = :id
  end

  test "INITIAL_PURCHASE -> no customer exists -> sets the payment processor to revenue_cat" do
    @pay_customer.destroy

    assert_changes -> { Pay::RevenueCat::Customer.count } do
      Pay::RevenueCat::Webhooks::Renewal.new.call(
        initial_purchase_params
      )
    end

    @owner.reload

    assert_equal(
      @owner.id,
      @owner.pay_customers.find_by(processor: :revenue_cat).processor_id.to_i
    )
  end

  test "INITIAL_PURCHASE -> custom integration_model_field -> creates customer via that field" do
    Pay::RevenueCat.integration_model_field = :email
    @pay_customer.destroy

    params = JSON.parse(file_fixture("initial_purchase.json").read)["event"].merge(
      "app_user_id" => @owner.email,
      "original_app_user_id" => @owner.email
    )

    assert_changes -> { Pay::RevenueCat::Customer.count } do
      Pay::RevenueCat::Webhooks::Renewal.new.call(params)
    end

    new_customer = @owner.reload.pay_customers.find_by(processor: :revenue_cat)
    assert_equal @owner.email, new_customer.processor_id
  end

  test "INITIAL_PURCHASE -> customer exists -> subscribes the customer" do
    assert_difference "Pay::Charge.count" do
      Pay::RevenueCat::Webhooks::Renewal.new.call(
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

    Pay::RevenueCat::Webhooks::Renewal.new.call(
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
      subscription, Pay::RevenueCat::Charge.last.subscription
    )
  end

  test "RENEWAL -> iOS -> adds a new charge to the customer" do
    payload = initial_purchase_params
    subscription = create_subscription(payload)
    create_initial_charge(payload, subscription)

    assert_difference -> { @pay_customer.reload.charges.count } do
      Pay::RevenueCat::Webhooks::Renewal.new.call(
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

    Pay::RevenueCat::Webhooks::Renewal.new.call(
      renewal_after_cancellation_params
    )

    subscription.reload
    assert_equal "active", subscription.status
    assert_equal Time.at(1_740_658_577), subscription.ends_at
    assert_equal Time.at(1_740_658_577), subscription.current_period_end
  end

  # we may not get here in real life but what happens with sandbox accounts
  # is if you have already had a subscriotion expire and start a new one
  # revenue_cat send a renewal event. If you're re-seeding your database this
  # can be very annoying.
  test "RENEWAL -> iOS -> creates a new subscription if one does not exist" do
    assert_difference "Pay::RevenueCat::Subscription.count" do
      Pay::RevenueCat::Webhooks::Renewal.new.call(
        renewal_after_cancellation_params
      )
    end

    subscription = Pay::RevenueCat::Subscription.last

    assert_equal "active", subscription.status
    assert_equal Time.at(1_740_658_577), subscription.ends_at
    assert_equal Time.at(1_740_658_577), subscription.current_period_end
  end

  test "RENEWAL -> Android -> adds a charge" do
    payload = android_initial_purchase_params
    subscription = create_subscription(payload)
    create_initial_charge(payload, subscription)

    assert_difference "Pay::Charge.count" do
      Pay::RevenueCat::Webhooks::Renewal.new.call(
        renewal_android_params
      )
    end
  end

  test "INITIAL_PURCHASE -> customer has existing RC subscriptions with different transaction id -> creates new subscription" do
    other_subscription = @pay_customer.subscriptions.create!(
      name: "annual",
      processor_plan: "annual",
      processor_id: "9999999999999999",
      status: :active,
      current_period_start: 1.month.ago,
      current_period_end: 11.months.from_now
    )

    assert_difference "Pay::RevenueCat::Subscription.count" do
      Pay::RevenueCat::Webhooks::Renewal.new.call(initial_purchase_params)
    end

    assert other_subscription.reload.persisted?
  end

  test "RENEWAL -> finds RevenueCat customer even when it is not the default payment processor" do
    payload = initial_purchase_params
    subscription = create_subscription(payload)
    create_initial_charge(payload, subscription)

    # Simulate the user having a different default payment processor (e.g. Stripe)
    @pay_customer.update!(default: false)

    assert_difference -> { @pay_customer.reload.charges.count } do
      Pay::RevenueCat::Webhooks::Renewal.new.call(renewal_params)
    end

    charge = @pay_customer.charges.last
    assert_equal renewal_params["transaction_id"], charge.processor_id
    assert_equal "revenue_cat", @pay_customer.processor
  end
end
