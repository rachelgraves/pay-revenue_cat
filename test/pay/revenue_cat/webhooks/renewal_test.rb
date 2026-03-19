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

  test "creates customer, subscription, and charge" do
    @pay_customer.destroy

    assert_difference ["Pay::RevenueCat::Customer.count", "Pay::RevenueCat::Subscription.count", "Pay::RevenueCat::Charge.count"] do
      Pay::RevenueCat::Webhooks::Renewal.new.call(initial_purchase_params)
    end
  end

  test "updates existing subscription on renewal" do
    subscription = create_subscription(initial_purchase_params)
    create_initial_charge(initial_purchase_params, subscription)

    assert_no_difference "Pay::RevenueCat::Subscription.count" do
      assert_difference "Pay::RevenueCat::Charge.count" do
        Pay::RevenueCat::Webhooks::Renewal.new.call(renewal_params)
      end
    end
  end

  test "runs within a transaction" do
    @pay_customer.destroy

    Pay::RevenueCat::Charge.stub(:create_from_event, ->(*) { raise ActiveRecord::RecordInvalid }) do
      assert_no_difference ["Pay::RevenueCat::Customer.count", "Pay::RevenueCat::Subscription.count"] do
        assert_raises ActiveRecord::RecordInvalid do
          Pay::RevenueCat::Webhooks::Renewal.new.call(initial_purchase_params)
        end
      end
    end
  end
end
