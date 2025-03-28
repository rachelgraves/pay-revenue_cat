# frozen_string_literal: true

module Pay
  module Webhooks
    class RevenuecatController < Pay::ApplicationController
      def create
        queue_event(verify_params.as_json)
        head :ok
      end

      private

      def queue_event(event)
        return unless Pay::Webhooks.delegator.listening?("revenuecat.#{params[:event][:type]}")

        record = Pay::Webhook.create!(processor: :revenuecat, event_type: params[:event][:type], event: event[:event])
        Pay::Webhooks::ProcessJob.perform_later(record)
      end

      def verify_params
        params.except(:action, :controller).permit!
      end
    end
  end
end
