module Pay
  module Revenuecat
    class TestController < ActionController::Base
      def index
        render plain: "revenuecat ok"
      end
    end
  end
end
