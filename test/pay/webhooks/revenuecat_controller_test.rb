require "test_helper"

module Pay
  class RevenuecatWebhooksControllerTest < ActionDispatch::IntegrationTest
    include Pay::Engine.routes.url_helpers
    include Pay::Revenuecat::Engine.routes.url_helpers

    test "should handle revenuecat post requests" do
      post webhooks_revenuecat_path
      assert_response :bad_request
    end
  end
end
