# # frozen_string_literal: true

module Pay
  module Webhooks
    class RevenuecatController < Pay::ApplicationController
      def create
        render plain: "", status: :bad_request
      end
    end
  end
end
