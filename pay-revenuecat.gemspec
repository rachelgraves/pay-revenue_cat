# frozen_string_literal: true

require_relative "lib/pay/revenuecat/version"

Gem::Specification.new do |spec|
  spec.name = "pay-revenuecat"
  spec.version = Pay::Revenuecat::VERSION
  spec.authors = ["Rachel J Graves"]
  spec.email = ["rachel@racheljgraves.co.uk"]

  spec.summary = "RevenueCat processor for the pay gem (pay-rails)."
  spec.description = "Adds RevenueCat as a payment processor for the pay gem in Rails apps."
  spec.homepage = "https://github.com/rachelgraves/pay-revenuecat"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir[
    "{app,config,db,lib}/**/*",
    "MIT-LICENSE",
    "Rakefile",
    "README.md"
  ]
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport"
  spec.add_dependency "pay", "~> 8"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "rails", ">= 8.0"
  spec.add_dependency "railties", ">= 7.1", "< 9"
  spec.add_development_dependency "debug"
  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
