require "test_helper"

class Pay::Revenuecat::Webhooks::InitialPurchaseTest < ActiveSupport::TestCase
  def setup
    @pay_customer = pay_customers(:revenuecat)
  end
  # test "exists" do
  #   assert_respond_to Pay::Revenuecat::Webhooks::InitialPurchase, :call
  # end
  test "sets payment processor to revenuecat" do
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
  end

  private

  def initial_purchase_params
    JSON.parse(
      file_fixture("initial_purchase.json").read
    )["event"]
  end
end
