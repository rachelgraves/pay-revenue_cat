# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "pay/revenuecat"

require "minitest/autorun"

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
