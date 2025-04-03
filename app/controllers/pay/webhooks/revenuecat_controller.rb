# frozen_string_literal: true

module Pay
  module Webhooks
    class RevenuecatController < Pay::ApplicationController
      def create
        queue_event(verify_params)
        head :ok
      end

      private

      def queue_event(event)
        return unless listening?(event)

        record = Pay::Webhook.create!(
          processor: :revenuecat,
          event_type: event[:event][:type],
          event: event[:event]
        )

        Pay::Webhooks::ProcessJob.perform_later(record)
      end

      def verify_params
        params.except(:action, :controller).permit!
      end

      def listening?(event)
        Pay::Webhooks.delegator.listening?("revenuecat.#{event[:event][:type]}")
      end
    end
  end
end
