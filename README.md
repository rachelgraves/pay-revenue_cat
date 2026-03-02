# Pay::RevenueCat

TODO: Delete this and the text below, and describe your gem

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/pay/revenue_cat`. To experiment with that code, run `bin/console` for an interactive prompt.

## Installation

TODO: Replace `UPDATE_WITH_YOUR_GEM_NAME_IMMEDIATELY_AFTER_RELEASE_TO_RUBYGEMS_ORG` with your gem name right after releasing it to RubyGems.org. Please do not do it earlier due to security reasons. Alternatively, replace this section with instructions to install your gem from git if you don't plan to release to RubyGems.org.

Install the gem and add to the application's Gemfile by executing:

```bash
bundle add UPDATE_WITH_YOUR_GEM_NAME_IMMEDIATELY_AFTER_RELEASE_TO_RUBYGEMS_ORG
```

If bundler is not being used to manage dependencies, install the gem by executing:

```bash
gem install UPDATE_WITH_YOUR_GEM_NAME_IMMEDIATELY_AFTER_RELEASE_TO_RUBYGEMS_ORG
```

## Usage

### Configuration

Add an initializer to configure the gem:

```ruby
# config/initializers/revenue_cat.rb
Pay::RevenueCat.integration_model_klass = "User"  # default

# Only needed if your RevenueCat app_user_id is not the model's primary key.
# For example, if app_user_id is a UUID stored in a `uuid` column:
Pay::RevenueCat.integration_model_field = :uuid  # default: :id
```

### How customer resolution works

This differs slightly from the Stripe and Braintree processors in the Pay gem.

**Stripe/Braintree** never need to look up the owner model directly — they always find `Pay::Customer` by `processor_id` alone, since the processor assigns a customer ID on creation.

**RevenueCat** doesn't have a server-side customer creation step. The first webhook (`INITIAL_PURCHASE`) is the moment we create the `Pay::Customer` record. At that point we must look up the owner model using `app_user_id` — that's what `integration_model_field` controls.

```
INITIAL_PURCHASE (first time)
  └─ Pay::Customer not found by processor_id
      └─ Look up owner: User.find_by!(integration_model_field => app_user_id)
          └─ Create Pay::Customer with processor_id = app_user_id

All subsequent events (RENEWAL, CANCELLATION, etc.)
  └─ Pay::Customer found by processor_id  ← same fast path as Stripe/Braintree
```

After the first purchase, `processor_id` is always `app_user_id`, so all later events use the fast path without touching the owner model.

## Development

This project uses [MISE](https://mise.jdx.dev/) for Ruby version management. The required Ruby version is specified in `.tool-versions`. After installing MISE and checking out the repo, run `bin/setup` to install dependencies.

```bash
# Run all tests and rubocop
bundle exec rake

# Run tests only
bundle exec rake test

# Run a single test file
bundle exec rake test TEST=test/pay/revenue_cat/webhooks/renewal_test.rb

# Run a single test by name
bundle exec rake test TEST=test/pay/revenue_cat/webhooks/renewal_test.rb TESTOPTS="--name=test_RENEWAL_iOS_updates_subscription_attributes"
```

You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/pay-revenue_cat. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/pay-revenue_cat/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Pay::RevenueCat project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/pay-revenue_cat/blob/main/CODE_OF_CONDUCT.md).
