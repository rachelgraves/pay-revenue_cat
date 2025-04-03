# frozen_string_literal: true

require "test_helper"

class Pay::Revenuecat::Webhooks::ExpirationTest < ActiveSupport::TestCase
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
      customer: @pay_customer
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

  test "iOS expiration" do
    payload = initial_purchase_params
    subscription = create_subscription(payload)
    create_initial_charge(payload, subscription)

    Pay::Revenuecat::Webhooks::Expiration.new.call(
      expiration_params["event"]
    )

    subscription.reload

    assert_equal "canceled", subscription.status
    assert_equal Time.at(1_740_141_539), subscription.ends_at
  end

  test "android expiration" do
    payload = android_initial_purchase_params
    subscription = create_subscription(payload)
    create_initial_charge(payload, subscription)

    Pay::Revenuecat::Webhooks::Expiration.new.call(
      android_expiration_params["event"]
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

  def expiration_params
    parse_fixture("expiration.json")
  end

  def android_expiration_params
    parse_fixture("expiration_android_monthly.json")
  end

  def android_initial_purchase_params
    parse_fixture("initial_purchase_android_monthly.json")
  end

  def parse_fixture(filename)
    JSON.parse(file_fixture(filename).read)
  end
end
