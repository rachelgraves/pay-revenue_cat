# frozen_string_literal: true

require "test_helper"

class Pay::RevenuecatTest < ActiveSupport::TestCase
  def test_that_it_has_a_version_number
    refute_nil ::Pay::Revenuecat::VERSION
  end

  test "#intgration_model_klass is 'User'" do
    assert_equal "User", ::Pay::Revenuecat.integration_model_klass
  end

  test "#integration_model_klass can be set to a different model" do
    assert_equal "Foo", ::Pay::Revenuecat.integration_model_klass = "Foo"
  end
end
