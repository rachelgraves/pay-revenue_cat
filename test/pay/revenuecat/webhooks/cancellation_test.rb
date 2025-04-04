# frozen_string_literal: true

require "test_helper"

class Pay::Revenuecat::Webhooks::CancellationTest < ActiveSupport::TestCase
  def setup
    @pay_customer = pay_customers(:revenuecat)
  end

  def create_subscription(payload)
    Pay::Revenuecat::Subscription.create!(
      name: "todo: Figure out what should go here",
      processor_plan: payload["event"]["product_id"],
      processor_id: payload["event"]["original_transaction_id"],
      current_period_start: 27.days.ago,
      current_period_end: 1.month.from_now.beginning_of_month,
      status: :active,
      customer: @pay_customer,
      data: {
        store: payload["event"]["store"]
      }
    )
  end

  def create_initial_charge(payload, subscription)
    Pay::Revenuecat::Charge.create!(
      subscription: subscription,
      processor_id: payload["event"]["transaction_id"],
      amount: 9.99,
      customer: @pay_customer
    )
  end

  test "iOS cancellation" do
    payload = initial_purchase_params
    subscription = create_subscription(payload)
    create_initial_charge(payload, subscription)

    assert_no_changes "Pay::Revenuecat::Charge.count" do
      Pay::Revenuecat::Webhooks::Cancellation.new.call(
        cancellation_params["event"]
      )
    end

    subscription.reload

    assert_equal "canceled", subscription.status
    assert_equal Time.at(1_740_141_539), subscription.ends_at
    assert_equal "UNSUBSCRIBE", subscription.data["cancel_reason"]
    assert_equal "APP_STORE", subscription.data["store"]
  end

  test "iOS cancellation after expiration" do
    payload = initial_purchase_params
    subscription = create_subscription(payload)
    create_initial_charge(payload, subscription)
    # doesn't expire it

    subscription.update!(status: "canceled")

    Pay::Revenuecat::Webhooks::Cancellation.new.call(
      cancellation_params["event"]
    )

    assert_equal "canceled", subscription.reload.status
  end

  test "android cancellation" do
    payload = android_initial_purchase_params
    subscription = create_subscription(payload)
    create_initial_charge(payload, subscription)

    Pay::Revenuecat::Webhooks::Cancellation.new.call(
      android_cancellation_params["event"]
    )

    subscription.reload

    assert_equal 1, subscription.charges.count
    assert_equal "canceled", subscription.status
    assert_equal Time.at(1_740_571_667), subscription.ends_at
  end

  private

  def initial_purchase_params
    parse_fixture("initial_purchase.json")
  end

  def cancellation_params
    parse_fixture("cancellation.json")
  end

  def android_cancellation_params
    parse_fixture("cancellation_android.json")
  end

  def android_initial_purchase_params
    parse_fixture("initial_purchase_android_monthly.json")
  end

  def parse_fixture(filename)
    JSON.parse(file_fixture(filename).read)
  end
end
