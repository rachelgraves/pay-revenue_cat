# frozen_string_literal: true

module Pay
  module Webhooks
    class RevenueCatController < Pay::ApplicationController
      if Rails.application.config.action_controller.default_protect_from_forgery
        skip_before_action :verify_authenticity_token
      end

      def create
        queue_event(verified_event)
        head :ok
      rescue Pay::RevenueCat::InvalidEventSignature
        head :unauthorized
      end

      private

      def verified_event
        signature = request.headers["Authorization"]
        raise Pay::RevenueCat::InvalidEventSignature unless valid_signature?(signature)

        verify_params
      end

      def valid_signature?(signature)
        return false unless signature.present?

        scheme, token = signature.split(" ", 2)

        return false unless scheme == "Basic"
        return false unless token == Pay::RevenueCat.webhook_access_key

        true
      end

      def queue_event(event)
        return unless listening?(event)

        record = Pay::Webhook.create!(
          processor: :revenue_cat,
          event_type: event[:event][:type],
          event: event[:event]
        )

        Pay::Webhooks::ProcessJob.perform_later(record)
      end

      def verify_params
        params.except(:action, :controller).permit!
      end

      def listening?(event)
        Pay::Webhooks.delegator.listening?("revenue_cat.#{event[:event][:type]}")
      end
    end
  end
end
