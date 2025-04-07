# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "pay/revenuecat"

require "minitest/autorun"
require "minitest/reporters"

Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

require File.expand_path("dummy/config/environment.rb", __dir__)
ActiveRecord::Migrator.migrations_paths = [
  File.expand_path("dummy/db/migrate", __dir__),
  File.expand_path("../db/migrate", __dir__)
]
require "rails/test_help"
Rails.backtrace_cleaner.remove_silencers!

# Filter out Minitest backtrace while allowing backtrace from other libraries
# to be shown.
Minitest.backtrace_filter = Minitest::BacktraceFilter.new

# Load fixtures from the engine
if ActiveSupport::TestCase.respond_to?(:fixture_paths=)
  ActiveSupport::TestCase.fixture_paths << File.expand_path("fixtures", __dir__)
  ActionDispatch::IntegrationTest.fixture_paths << File.expand_path("fixtures", __dir__)
elsif ActiveSupport::TestCase.respond_to?(:fixture_path=)
  ActiveSupport::TestCase.fixture_path = File.expand_path("fixtures", __dir__)
  ActionDispatch::IntegrationTest.fixture_path = ActiveSupport::TestCase.fixture_path
end
ActiveSupport::TestCase.file_fixture_path = File.expand_path("fixtures/files", __dir__)
ActiveSupport::TestCase.fixtures :all

def initial_purchase_params
  parse_fixture("initial_purchase.json")
end

def renewal_params
  parse_fixture("renewal.json")
end

def renewal_after_cancellation_params
  parse_fixture("renewal_after_expiration_without_initial_purchase.json")
end

def renewal_android_params
  parse_fixture("renewal_android_monthly.json")
end

def android_initial_purchase_params
  parse_fixture("initial_purchase_android_monthly.json")
end

def cancellation_params
  parse_fixture("cancellation.json")
end

def android_cancellation_params
  parse_fixture("cancellation_android.json")
end

def expiration_params
  parse_fixture("expiration.json")
end

def android_expiration_params
  parse_fixture("expiration_android_monthly.json")
end

def parse_fixture(filename)
  JSON.parse(file_fixture(filename).read)["event"].merge({
    "app_user_id" => @owner.id,
    "original_app_user_id" => @owner.id
  })
end

def create_subscription(payload)
  Pay::Revenuecat::Subscription.create!(
    name: "todo: Figure out what should go here",
    processor_plan: payload["product_id"],
    processor_id: payload["original_transaction_id"],
    current_period_start: 27.days.ago,
    current_period_end: 1.month.from_now.beginning_of_month,
    status: :active,
    customer: @pay_customer,
    data: {
      store: payload["store"]
    }
  )
end

def create_initial_charge(payload, subscription)
  Pay::Revenuecat::Charge.create!(
    subscription: subscription,
    processor_id: payload["transaction_id"],
    amount: 9.99,
    customer: @pay_customer
  )
end
