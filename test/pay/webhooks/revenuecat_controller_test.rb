require "test_helper"

module Pay
  class RevenuecatWebhooksControllerTest < ActionDispatch::IntegrationTest
    include Pay::Engine.routes.url_helpers
    include Pay::Revenuecat::Engine.routes.url_helpers

    def setup
      @pay_user = users(:revenuecat)
    end

    # test "should handle revenuecat post requests" do
    #   post webhooks_revenuecat_path
    #   assert_response :bad_request
    # end
    #
    # test "should parse a revenuecat webhook" do
    #   # pay_customer = pay_customers(:revenuecat)
    #   # pay_customer.update(processor_id: stripe_event.data.object.customer)
    #   assert_difference "Pay::Webhook.count" do
    #     assert_enqueued_with(job: Pay::Webhooks::ProcessJob) do
    #       post webhooks_revenuecat_path, params: revenuecat_params, as: :json
    #       assert_response :success
    #     end
    #   end
    #
    #   assert_difference "Pay::Charge.count" do
    #     perform_enqueued_jobs
    #   end
    # end

    private

    def revenuecat_params
      JSON.parse(
        file_fixture("initial_purchase.json").read
      )
    end
  end
end
