require "test_helper"

class Pay::Revenuecat::EngineTest < ActionDispatch::IntegrationTest
  test "engine is defined and loaded" do
    assert defined?(Pay::Revenuecat::Engine)
  end

  test "pay processor is enabled" do
    assert Pay::Revenuecat.enabled?
  end

  test "engine route is mounted in dummy app" do
    get "/pay-revenuecat/test"
    assert_response :success
  end
end
