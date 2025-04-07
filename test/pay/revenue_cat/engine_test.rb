# frozen_string_literal: true

require "test_helper"

class Pay::RevenueCat::EngineTest < ActionDispatch::IntegrationTest
  test "engine is defined and loaded" do
    assert defined?(Pay::RevenueCat::Engine)
  end

  test "pay processor is enabled" do
    assert Pay::RevenueCat.enabled?
  end
end
