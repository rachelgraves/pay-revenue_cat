# frozen_string_literal: true

require "test_helper"

class Pay::RevenueCatTest < ActiveSupport::TestCase
  def test_that_it_has_a_version_number
    refute_nil ::Pay::RevenueCat::VERSION
  end

  test "#integration_model_klass can be set and read" do
    assert_equal "Foo", ::Pay::RevenueCat.integration_model_klass = "Foo"
    assert_equal "Foo", ::Pay::RevenueCat.integration_model_klass
  end
end
