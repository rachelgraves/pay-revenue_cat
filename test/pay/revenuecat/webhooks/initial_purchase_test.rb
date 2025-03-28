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
      Pay::Revenuecat::Webhooks::InitialPurchase.new.call(revenuecat_params["event"])
    end
  end

  private

  def revenuecat_params
    JSON.parse(
      file_fixture("initial_purchase.json").read
    )
  end
end
