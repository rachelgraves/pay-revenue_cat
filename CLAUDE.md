# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

`pay-revenue_cat` is a Ruby gem that adds RevenueCat as a payment processor for the [Pay gem](https://github.com/pay-rails/pay) (pay-rails). It handles RevenueCat webhook events to keep subscription state in sync within a Rails application.

## Commands

```bash
# Install dependencies
bin/setup

# Run all tests and rubocop
bundle exec rake

# Run tests only
bundle exec rake test

# Run a single test file
bundle exec rake test TEST=test/pay/revenue_cat/webhooks/renewal_test.rb

# Run a single test by name
bundle exec rake test TEST=test/pay/revenue_cat/webhooks/renewal_test.rb TESTOPTS="--name=test_RENEWAL_iOS_updates_subscription_attributes"

# Run rubocop
bundle exec rubocop

# Interactive console
bin/console
```

## Architecture

### Gem Structure

This is a Rails Engine gem. The main entry point is `lib/pay/revenue_cat.rb`, which:
- Autoloads webhook handler classes
- Configures Pay's webhook event subscriptions via `configure_webhooks`
- Exposes `webhook_access_key` (read from env/credentials via `Pay::Env`)
- Provides `integration_model_klass` (default: `"User"`) — the model that `pay_customer` belongs to

The engine (`lib/pay/revenue_cat/engine.rb`) mounts the webhook route and calls `configure_webhooks` at initialization.

### Webhook Flow

1. RevenueCat POSTs to `POST /pay/webhooks/revenue_cat`
2. `Pay::Webhooks::RevenueCatController#create` authenticates via `Authorization: Basic <webhook_access_key>`
3. Valid events (excluding TEST) are persisted as `Pay::Webhook` records and enqueued via `Pay::Webhooks::ProcessJob`
4. The job dispatches to the appropriate handler via Pay's event subscription system

**Subscribed events and their handlers:**
- `INITIAL_PURCHASE` → `Pay::RevenueCat::Webhooks::Renewal`
- `RENEWAL` → `Pay::RevenueCat::Webhooks::Renewal`
- `CANCELLATION` → `Pay::RevenueCat::Webhooks::Cancellation`
- `EXPIRATION` → `Pay::RevenueCat::Webhooks::Expiration`
- `TEST` → logged and discarded (no `Pay::Webhook` record created)

### Webhook Handlers (`lib/pay/revenue_cat/webhooks/`)

- **Renewal**: Handles both `INITIAL_PURCHASE` and `RENEWAL`. Finds or creates the `Pay::RevenueCat::Customer` using `event["app_user_id"]` looked up via `integration_model_klass`. Creates/updates `Pay::RevenueCat::Subscription` and always creates a `Pay::RevenueCat::Charge`.
- **Cancellation**: Finds subscription by `original_transaction_id`. Sets status to `:active` (if `expiration_at_ms` is in the future) or `:canceled`. Stores `cancel_reason` in `data`.
- **Expiration**: Finds subscription, sets status to `"canceled"`, stores `expiration_reason` in `data`.

### Models (`app/models/pay/revenue_cat/`)

- `Customer` < `Pay::Customer` — scoped to `processor: "revenue_cat"`. The `subscribe` method creates subscriptions directly (no API calls). `update_api_record` is a no-op.
- `Subscription` < `Pay::Subscription` — `resumable?` always returns false.
- `Charge` < `Pay::Charge` — `api_record` returns self (no external API). `refund!` is a stub (TODO).

### Configuration

`integration_model_klass` determines which model is looked up by `app_user_id` in webhook events. Set it in an initializer:

```ruby
Pay::RevenueCat.integration_model_klass = "User"  # default
```

The webhook access key is read via `Pay::Env` — set `REVENUE_CAT_WEBHOOK_ACCESS_KEY` in the environment or credentials.

### Tests

Tests use Minitest with the dummy Rails app in `test/dummy/`. Fixtures are in `test/fixtures/`. JSON fixture files in `test/fixtures/files/` represent real RevenueCat webhook payloads. The `parse_fixture` helper in `test_helper.rb` injects `@owner.id` as both `app_user_id` and `original_app_user_id`.

Test fixtures have two Pay customers: `revenue_cat` (owned by `User`) and `revenue_cat_account` (owned by `Account`), used to test `integration_model_klass` flexibility.
