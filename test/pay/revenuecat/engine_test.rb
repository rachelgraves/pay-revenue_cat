require "test_helper"

class Pay::Revenuecat::EngineTest < ActiveSupport::TestCase
  test "engine is defined and loaded" do
    assert defined?(Pay::Revenuecat::Engine)
    assert_kind_of Rails::Engine, Pay::Revenuecat::Engine
  end

  test "pay processor is enabled" do
    assert Pay::Revenuecat.enabled?
  end
end
