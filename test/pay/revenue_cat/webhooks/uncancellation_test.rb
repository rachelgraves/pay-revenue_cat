# frozen_string_literal: true

require "test_helper"

class Pay::RevenueCat::Webhooks::UncancellationTest < ActiveSupport::TestCase
  def setup
    Pay::RevenueCat.integration_model_klass = "User"
    @pay_customer = pay_customers(:revenue_cat)
    @owner = @pay_customer.owner
  end

  test "uncancellation reactivates a pending-cancellation subscription" do
    payload = uncancellation_params
    subscription = create_subscription(payload)
    subscription.update!(
      status: :active,
      ends_at: 30.days.from_now,
      data: {store: payload["store"], cancel_reason: "UNSUBSCRIBE"}
    )

    assert_no_changes "Pay::RevenueCat::Charge.count" do
      Pay::RevenueCat::Webhooks::Uncancellation.new.call(uncancellation_params)
    end

    subscription.reload

    assert_equal "active", subscription.status
    assert_nil subscription.ends_at
    assert_nil subscription.data["cancel_reason"]
  end

  test "creates subscription when none exists" do
    assert_difference "Pay::RevenueCat::Subscription.count" do
      Pay::RevenueCat::Webhooks::Uncancellation.new.call(uncancellation_params)
    end

    subscription = @pay_customer.reload.subscriptions.last
    assert_equal "active", subscription.status
    assert_nil subscription.ends_at
  end

  test "creates customer and subscription when neither exists" do
    @pay_customer.destroy

    assert_difference ["Pay::RevenueCat::Customer.count", "Pay::RevenueCat::Subscription.count"] do
      Pay::RevenueCat::Webhooks::Uncancellation.new.call(uncancellation_params)
    end
  end

  test "runs within a transaction" do
    @pay_customer.destroy

    Pay::RevenueCat::Subscription.stub(:find_by, ->(*) { raise ActiveRecord::RecordInvalid }) do
      assert_no_difference "Pay::RevenueCat::Customer.count" do
        assert_raises ActiveRecord::RecordInvalid do
          Pay::RevenueCat::Webhooks::Uncancellation.new.call(uncancellation_params)
        end
      end
    end
  end
end
