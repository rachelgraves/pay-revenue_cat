# frozen_string_literal: true

require_relative "revenuecat/version"
require "pay/revenuecat/engine"

module Pay
  module Revenuecat
    class Error < StandardError; end

    def self.enabled?
      true
    end
  end
end
