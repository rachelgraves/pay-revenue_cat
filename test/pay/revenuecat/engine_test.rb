# frozen_string_literal: true

require "test_helper"

class Pay::Revenuecat::EngineTest < ActionDispatch::IntegrationTest
  test "engine is defined and loaded" do
    assert defined?(Pay::Revenuecat::Engine)
  end

  test "pay processor is enabled" do
    assert Pay::Revenuecat.enabled?
  end
end
