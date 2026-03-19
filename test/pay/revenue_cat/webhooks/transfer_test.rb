# frozen_string_literal: true

require "test_helper"

class Pay::RevenueCat::Webhooks::TransferTest < ActiveSupport::TestCase
  def setup
    Pay::RevenueCat.integration_model_klass = "User"
    @pay_customer = pay_customers(:revenue_cat)
    @owner = @pay_customer.owner
  end

  test "transfers subscriptions and charges to target customer" do
    subscription = create_subscription(initial_purchase_params)
    charge = create_initial_charge(initial_purchase_params, subscription)
    target_owner = User.create!(email: "target@example.com", first_name: "Target", last_name: "User")

    event = {
      "transferred_from" => [@pay_customer.processor_id],
      "transferred_to" => [target_owner.id.to_s]
    }

    Pay::RevenueCat::Webhooks::Transfer.new.call(event)

    subscription.reload
    charge.reload
    target_customer = Pay::Customer.find_by(processor: :revenue_cat, processor_id: target_owner.id.to_s)
    assert_equal target_customer.id, subscription.customer_id
    assert_equal target_customer.id, charge.customer_id
  end

  test "skips when source customer not found" do
    event = {
      "transferred_from" => ["nonexistent-id"],
      "transferred_to" => [@owner.id.to_s]
    }

    assert_nothing_raised do
      Pay::RevenueCat::Webhooks::Transfer.new.call(event)
    end
  end

  test "skips when target owner not found" do
    event = {
      "transferred_from" => [@pay_customer.processor_id],
      "transferred_to" => ["nonexistent-id"]
    }

    assert_nothing_raised do
      Pay::RevenueCat::Webhooks::Transfer.new.call(event)
    end
  end

  test "runs within a transaction" do
    subscription = create_subscription(initial_purchase_params)
    create_initial_charge(initial_purchase_params, subscription)
    target_owner = User.create!(email: "target@example.com", first_name: "Target", last_name: "User")

    event = {
      "transferred_from" => [@pay_customer.processor_id],
      "transferred_to" => [target_owner.id.to_s]
    }

    Pay::RevenueCat::Customer.stub(:find_or_create_by_processor_id, ->(*) { raise ActiveRecord::RecordInvalid }) do
      assert_raises ActiveRecord::RecordInvalid do
        Pay::RevenueCat::Webhooks::Transfer.new.call(event)
      end
    end

    subscription.reload
    assert_equal @pay_customer.id, subscription.customer_id
  end
end
