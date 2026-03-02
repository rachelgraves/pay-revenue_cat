# frozen_string_literal: true

require "test_helper"

class Pay::RevenueCat::SubscriptionTest < ActiveSupport::TestCase
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
end
