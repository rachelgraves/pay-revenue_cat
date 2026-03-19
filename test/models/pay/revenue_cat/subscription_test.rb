# frozen_string_literal: true

require "test_helper"

class Pay::RevenueCat::SubscriptionTest < ActiveSupport::TestCase
  def setup
    Pay::RevenueCat.integration_model_klass = "User"
    @pay_customer = pay_customers(:revenue_cat)
    @owner = @pay_customer.owner
  end

  test "#resumable returns false" do
    # subscriptions are controlled on native apps, not by the backend
    assert_equal false, Pay::RevenueCat::Subscription.new.resumable?
  end

  test "#paused? returns true when status is paused" do
    assert Pay::RevenueCat::Subscription.new(status: :paused).paused?
  end

  test "#paused? returns false when status is active" do
    refute Pay::RevenueCat::Subscription.new(status: :active).paused?
  end

  test "#paused? returns false when status is canceled" do
    refute Pay::RevenueCat::Subscription.new(status: :canceled).paused?
  end

  test ".find_or_create_from_event creates subscription when none exists" do
    event = initial_purchase_params

    assert_difference "Pay::RevenueCat::Subscription.count" do
      subscription = Pay::RevenueCat::Subscription.find_or_create_from_event(@pay_customer, event)

      assert_equal event["presented_offering_id"], subscription.name
      assert_equal event["product_id"], subscription.processor_plan
      assert_equal event["original_transaction_id"], subscription.processor_id
      assert_equal Time.at(event["expiration_at_ms"] / 1000), subscription.ends_at
      assert_equal event["store"], subscription.data["store"]
      assert_equal "active", subscription.status
    end
  end

  test ".find_or_create_from_event updates existing subscription" do
    subscription = create_subscription(initial_purchase_params)

    assert_no_difference "Pay::RevenueCat::Subscription.count" do
      result = Pay::RevenueCat::Subscription.find_or_create_from_event(@pay_customer, renewal_params)

      assert_equal subscription.id, result.id
      result.reload
      assert_equal "active", result.status
      assert_equal Time.at(renewal_params["expiration_at_ms"] / 1000), result.ends_at
      assert_equal Time.at(renewal_params["expiration_at_ms"] / 1000), result.current_period_end
    end
  end

  test ".subscription_attributes builds correct attributes from event" do
    event = initial_purchase_params
    attrs = Pay::RevenueCat::Subscription.subscription_attributes(event)

    assert_equal event["presented_offering_id"], attrs[:name]
    assert_equal event["product_id"], attrs[:plan]
    assert_equal event["original_transaction_id"], attrs[:processor_id]
    assert_equal Time.at(event["purchased_at_ms"] / 1000), attrs[:current_period_start]
    assert_equal Time.at(event["expiration_at_ms"] / 1000), attrs[:current_period_end]
    assert_equal({store: event["store"]}, attrs[:data])
    assert_equal :active, attrs[:status]
    assert_equal false, attrs[:metered]
  end

  test ".renewal_attributes only includes period and status fields" do
    event = renewal_params
    attrs = Pay::RevenueCat::Subscription.renewal_attributes(event)

    assert_equal %i[status ends_at current_period_start current_period_end].sort, attrs.keys.sort
  end
end
