require "test_helper"

module Pay
  class RevenueCatWebhooksControllerTest < ActionDispatch::IntegrationTest
    include Pay::Engine.routes.url_helpers
    include Pay::RevenueCat::Engine.routes.url_helpers

    def setup
      Pay::RevenueCat.integration_model_klass = "User"
      Pay::RevenueCat.stubs(:webhook_access_key).returns("1234567")

      @owner = users(:revenue_cat)
      @pay_customer = pay_customers(:revenue_cat)
      @pay_customer.update!(processor_id: @owner.id)
    end

    test "fails with invalid authentication" do
      post(
        webhooks_revenue_cat_path,
        params: {},
        as: :json,
        headers: {Authorization: "Basic 7654321"}
      )

      assert_response :unauthorized
    end

    test "fails without authentication" do
      post(
        webhooks_revenue_cat_path,
        params: {},
        as: :json
      )

      assert_response :unauthorized
    end

    test "fails with incorrect type of authentication" do
      post(
        webhooks_revenue_cat_path,
        params: {},
        as: :json,
        headers: {Authorization: "Bearer 1234567"}
      )

      assert_response :unauthorized
    end

    test "should handle INITIAL_PURCHASE event" do
      assert_difference "Pay::Webhook.count" do
        assert_enqueued_with(job: Pay::Webhooks::ProcessJob) do
          post(
            webhooks_revenue_cat_path,
            params: initial_purchase_params,
            as: :json,
            headers: {Authorization: "Basic 1234567"}
          )

          assert_response :success
        end
      end

      assert_difference "Pay::Charge.count" do
        perform_enqueued_jobs
      end
    end

    test "should handle RENEWAL event" do
      subscription = create_subscription(initial_purchase_params)
      create_initial_charge(initial_purchase_params, subscription)

      assert_difference "Pay::Webhook.count" do
        assert_enqueued_with(job: Pay::Webhooks::ProcessJob) do
          post(
            webhooks_revenue_cat_path,
            params: renewal_params,
            as: :json,
            headers: {Authorization: "Basic 1234567"}
          )
          assert_response :success
        end
      end

      assert_difference "Pay::Charge.count" do
        perform_enqueued_jobs
      end
    end

    test "should handle CANCELLATION event" do
      subscription = create_subscription(initial_purchase_params)
      create_initial_charge(initial_purchase_params, subscription)

      assert_difference "Pay::Webhook.count" do
        assert_enqueued_with(job: Pay::Webhooks::ProcessJob) do
          post(
            webhooks_revenue_cat_path,
            params: cancellation_params,
            as: :json,
            headers: {Authorization: "Basic 1234567"}
          )
          assert_response :success
        end
      end

      assert_changes -> { subscription.reload.status }, to: "canceled" do
        perform_enqueued_jobs
      end
    end

    test "should handle EXPIRATION event" do
      subscription = create_subscription(initial_purchase_params)
      create_initial_charge(initial_purchase_params, subscription)

      assert_difference "Pay::Webhook.count" do
        assert_enqueued_with(job: Pay::Webhooks::ProcessJob) do
          post(
            webhooks_revenue_cat_path,
            params: expiration_params,
            as: :json,
            headers: {Authorization: "Basic 1234567"}
          )
          assert_response :success
        end
      end

      assert_changes -> { subscription.reload.status }, to: "canceled" do
        perform_enqueued_jobs
      end
    end

    private

    def create_subscription(payload)
      Pay::RevenueCat::Subscription.create!(
        name: "todo: Figure out what should go here",
        processor_plan: payload["event"]["product_id"],
        processor_id: payload["event"]["original_transaction_id"],
        current_period_start: 27.days.ago,
        current_period_end: 1.month.from_now.beginning_of_month,
        status: :active,
        customer: @pay_customer
      )
    end

    def create_initial_charge(payload, subscription)
      Pay::RevenueCat::Charge.create!(
        subscription: subscription,
        processor_id: payload["event"]["transaction_id"],
        amount: 9.99,
        customer: @pay_customer
      )
    end

    def initial_purchase_params
      data = JSON.parse(file_fixture("initial_purchase.json").read)
      data["event"].merge!({
        "app_user_id" => @owner.id,
        "original_app_user_id" => @owner.id
      })
      data
    end

    def renewal_params
      data = JSON.parse(
        file_fixture("renewal.json").read
      )
      data["event"].merge!({
        "app_user_id" => @owner.id,
        "original_app_user_id" => @owner.id
      })
      data
    end

    def expiration_params
      data = JSON.parse(
        file_fixture("expiration.json").read
      )
      data["event"].merge!({
        "app_user_id" => @owner.id,
        "original_app_user_id" => @owner.id
      })
      data
    end

    def cancellation_params
      data = JSON.parse(
        file_fixture("cancellation.json").read
      )
      data["event"].merge!({
        "app_user_id" => @owner.id,
        "original_app_user_id" => @owner.id
      })
      data
    end
  end
end
