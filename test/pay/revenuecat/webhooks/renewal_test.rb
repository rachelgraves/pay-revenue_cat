# frozen_string_literal: true

require "test_helper"

class Pay::Revenuecat::Webhooks::RenewalTest < ActiveSupport::TestCase
  def setup
    @pay_customer = pay_customers(:revenuecat)
  end

  def create_subscription(payload)
    Pay::Revenuecat::Subscription.create!(
      name: "todo: Figure out what should go here",
      processor_plan: payload["product_id"],
      processor_id: payload["original_transaction_id"],
      current_period_start: 27.days.ago,
      current_period_end: 1.month.from_now.beginning_of_month,
      status: :active,
      customer: @pay_customer
    )
  end

  def create_initial_charge(payload, subscription)
    Pay::Revenuecat::Charge.create!(
      subscription: subscription,
      processor_id: payload["transaction_id"],
      amount: 9.99,
      customer: @pay_customer
    )
  end

  test "iOS renewal: updates subscription attributes" do
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
  end

  test "iOS renewal: adds a new charge" do
    payload = initial_purchase_params
    subscription = create_subscription(payload)
    create_initial_charge(payload, subscription)

    assert_difference "Pay::Charge.count" do
      Pay::Revenuecat::Webhooks::Renewal.new.call(
        renewal_params
      )
    end
  end

  test "iOS renewal: reactivates a cancelled subscription" do
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

  test "Android renewal: adds a charge" do
    payload = android_initial_purchase_params
    subscription = create_subscription(payload)
    create_initial_charge(payload, subscription)

    assert_difference "Pay::Charge.count" do
      Pay::Revenuecat::Webhooks::Renewal.new.call(
        renewal_android_params
      )
    end
  end

  private

  def initial_purchase_params
    parse_fixture("initial_purchase.json")
  end

  def renewal_params
    parse_fixture("renewal.json")
  end

  def renewal_after_cancellation_params
    parse_fixture("renewal_after_expiration_without_initial_purchase.json")
  end

  def renewal_android_params
    parse_fixture("renewal_android_monthly.json")
  end

  def android_initial_purchase_params
    parse_fixture("initial_purchase_android_monthly.json")
  end

  def parse_fixture(filename)
    JSON.parse(file_fixture(filename).read)["event"]
  end
end
