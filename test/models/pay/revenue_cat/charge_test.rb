# frozen_string_literal: true

require "test_helper"

class Pay::RevenueCat::ChargeTest < ActiveSupport::TestCase
  def setup
    Pay::RevenueCat.integration_model_klass = "User"
    @pay_customer = pay_customers(:revenue_cat)
    @owner = @pay_customer.owner
  end

  test ".create_from_event creates a charge with correct attributes" do
    event = initial_purchase_params
    subscription = create_subscription(event)

    assert_difference "Pay::RevenueCat::Charge.count" do
      charge = Pay::RevenueCat::Charge.create_from_event(@pay_customer, subscription, event)

      assert_equal event["transaction_id"], charge.processor_id
      assert_equal (event["price_in_purchased_currency"] * 100).to_i, charge.amount
      assert_equal event["metadata"], charge.metadata
      assert_equal @pay_customer, charge.customer
      assert_equal subscription, charge.subscription
    end
  end

  test ".create_from_event creates a charge from a renewal event" do
    subscription = create_subscription(initial_purchase_params)
    event = renewal_params.merge("price_in_purchased_currency" => 12.99)

    charge = Pay::RevenueCat::Charge.create_from_event(@pay_customer, subscription, event)

    assert_equal renewal_params["transaction_id"], charge.processor_id
    assert_equal 1299, charge.amount
  end
end
