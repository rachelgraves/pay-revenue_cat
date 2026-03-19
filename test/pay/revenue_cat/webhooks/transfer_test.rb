# frozen_string_literal: true

require "test_helper"

class Pay::RevenueCat::Webhooks::TransferTest < ActiveSupport::TestCase
  def setup
    Pay::RevenueCat.integration_model_klass = "User"
    @pay_customer = pay_customers(:revenue_cat)
    @owner = @pay_customer.owner
    @target_owner = User.create!(email: "target@example.com", first_name: "Target", last_name: "User")
    @target_customer = Pay::RevenueCat::Customer.create!(
      owner: @target_owner, processor: :revenue_cat,
      processor_id: @target_owner.id.to_s, default: false
    )
    @subscription = @pay_customer.subscriptions.create!(
      name: "test", processor_plan: "monthly", processor_id: "txn_123",
      status: :active, current_period_start: Time.current,
      current_period_end: 1.month.from_now
    )
  end

  test "transfers subscriptions and charges to target customer" do
    charge = Pay::RevenueCat::Charge.create!(
      customer: @pay_customer, subscription: @subscription,
      processor_id: "ch_123", amount: 999
    )

    event = {
      "transferred_from" => [@pay_customer.processor_id],
      "transferred_to" => [@target_customer.processor_id]
    }

    Pay::RevenueCat::Webhooks::Transfer.new.call(event)

    assert_equal @target_customer, @subscription.reload.customer
    assert_equal @target_customer, charge.reload.customer
  end

  test "creates target customer when not found" do
    @target_customer.destroy

    event = {
      "transferred_from" => [@pay_customer.processor_id],
      "transferred_to" => [@target_owner.id.to_s]
    }

    assert_difference "Pay::RevenueCat::Customer.count" do
      Pay::RevenueCat::Webhooks::Transfer.new.call(event)
    end

    assert_equal @target_owner.id.to_s, @subscription.reload.customer.processor_id
  end

  test "skips when source customer not found" do
    event = {
      "transferred_from" => ["nonexistent"],
      "transferred_to" => [@target_customer.processor_id]
    }

    assert_no_difference "Pay::RevenueCat::Subscription.count" do
      Pay::RevenueCat::Webhooks::Transfer.new.call(event)
    end
  end

  test "skips when target owner not found" do
    event = {
      "transferred_from" => [@pay_customer.processor_id],
      "transferred_to" => ["nonexistent_owner"]
    }

    Pay::RevenueCat::Webhooks::Transfer.new.call(event)

    assert_equal @pay_customer, @subscription.reload.customer
  end

  test "runs within a transaction" do
    Pay::RevenueCat::Charge.create!(
      customer: @pay_customer, subscription: @subscription,
      processor_id: "ch_123", amount: 999
    )

    Pay::RevenueCat::Customer.any_instance.stubs(:charges).raises(ActiveRecord::RecordInvalid)

    event = {
      "transferred_from" => [@pay_customer.processor_id],
      "transferred_to" => [@target_customer.processor_id]
    }

    assert_raises ActiveRecord::RecordInvalid do
      Pay::RevenueCat::Webhooks::Transfer.new.call(event)
    end

    assert_equal @pay_customer, @subscription.reload.customer
  end
end
