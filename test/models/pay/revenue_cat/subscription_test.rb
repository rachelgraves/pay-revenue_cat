# frozen_string_literal: true

require "test_helper"

class Pay::RevenueCat::SubscriptionTest < ActiveSupport::TestCase
  test "#resumable returns false" do
    # subscriptions are controlled on native apps, not by the backend
    assert_equal false, Pay::RevenueCat::Subscription.new.resumable?
  end
end
