# frozen_string_literal: true

require "test_helper"

class Pay::RevenueCat::CustomerTest < ActiveSupport::TestCase
  def setup
    Pay::RevenueCat.integration_model_klass = "User"
    Pay::RevenueCat.integration_model_field = :id
    @pay_customer = pay_customers(:revenue_cat)
    @owner = @pay_customer.owner
  end

  def teardown
    Pay::RevenueCat.integration_model_field = :id
  end

  test ".find_or_create_from_event returns existing customer" do
    event = {"app_user_id" => @pay_customer.processor_id}

    assert_no_difference "Pay::Customer.count" do
      result = Pay::RevenueCat::Customer.find_or_create_from_event(event)
      assert_equal @pay_customer, result
    end
  end

  test ".find_or_create_from_event creates customer when none exists" do
    @pay_customer.destroy
    event = {"app_user_id" => @owner.id.to_s}

    assert_difference "Pay::Customer.count" do
      result = Pay::RevenueCat::Customer.find_or_create_from_event(event)
      assert_equal @owner, result.owner
      assert_equal "revenue_cat", result.processor
      assert_equal @owner.id.to_s, result.processor_id
      assert_equal false, result.default
    end
  end

  test ".find_or_create_from_event uses custom integration_model_field" do
    Pay::RevenueCat.integration_model_field = :email
    @pay_customer.destroy
    event = {"app_user_id" => @owner.email}

    result = Pay::RevenueCat::Customer.find_or_create_from_event(event)
    assert_equal @owner.email, result.processor_id
  end

  test ".find_or_create_from_event raises when owner not found" do
    @pay_customer.destroy
    event = {"app_user_id" => "nonexistent"}

    assert_raises ActiveRecord::RecordNotFound do
      Pay::RevenueCat::Customer.find_or_create_from_event(event)
    end
  end

  test ".find_or_create_by_processor_id returns existing customer" do
    assert_no_difference "Pay::Customer.count" do
      result = Pay::RevenueCat::Customer.find_or_create_by_processor_id(@pay_customer.processor_id)
      assert_equal @pay_customer, result
    end
  end

  test ".find_or_create_by_processor_id creates customer when owner exists" do
    @pay_customer.destroy

    assert_difference "Pay::Customer.count" do
      result = Pay::RevenueCat::Customer.find_or_create_by_processor_id(@owner.id.to_s)
      assert_equal @owner, result.owner
    end
  end

  test ".find_or_create_by_processor_id returns nil when owner not found" do
    result = Pay::RevenueCat::Customer.find_or_create_by_processor_id("nonexistent")
    assert_nil result
  end

  test "#transfer_to moves subscriptions and charges to target customer" do
    subscription = create_subscription(initial_purchase_params)
    charge = create_initial_charge(initial_purchase_params, subscription)
    target_customer = pay_customers(:revenue_cat_account)

    @pay_customer.transfer_to(target_customer)

    subscription.reload
    charge.reload
    assert_equal target_customer.id, subscription.customer_id
    assert_equal target_customer.id, charge.customer_id
  end
end
