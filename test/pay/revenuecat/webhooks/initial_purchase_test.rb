require "test_helper"

class Pay::Revenuecat::Webhooks::InitialPurchaseTest < ActiveSupport::TestCase
  def setup
    @pay_customer = pay_customers(:revenuecat)
    @owner = @pay_customer.owner
  end

  test "no customer exists -> sets the payment processor to revenuecat" do
    @pay_customer.destroy

    assert_changes -> { Pay::Revenuecat::Customer.count } do
      Pay::Revenuecat::Webhooks::InitialPurchase.new.call(
        initial_purchase_params
      )
    end

    @owner.reload

    assert_equal(
      @owner.id,
      @owner.payment_processor.processor_id.to_i
    )
  end

  test "subscribes the customer" do
    assert_difference "Pay::Charge.count" do
      Pay::Revenuecat::Webhooks::InitialPurchase.new.call(
        initial_purchase_params
      )
    end

    subscription = @pay_customer.reload.subscriptions.first

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
  end

  private

  def initial_purchase_params
    JSON.parse(
      file_fixture("initial_purchase.json").read
    )["event"].merge(
      "app_user_id" => @owner.id,
      "original_app_user_id" => @owner.id
    )
  end
end
