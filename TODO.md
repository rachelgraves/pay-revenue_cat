# TODO

## Add `UNCANCELLATION` webhook support

RevenueCat fires `UNCANCELLATION` when a user re-enables auto-renewal after having cancelled (but before their subscription expired). Two fixture files have been added in preparation but the handler is not yet implemented.

### Files to create

- `lib/pay/revenue_cat/webhooks/uncancellation.rb` — handler class:
  - Find subscription by `original_transaction_id`
  - Set `status: :active`
  - Clear `cancel_reason` from `data`
- `test/pay/revenue_cat/webhooks/uncancellation_test.rb` — tests covering at minimum: uncancelling a soft-cancelled subscription restores `:active` status

### Files to update

- `lib/pay/revenue_cat.rb` — add `autoload :Uncancellation` and `events.subscribe "revenue_cat.UNCANCELLATION"`
- `test/test_helper.rb`:
  - Add `cancellation_pre_uncancellation_params` helper (fixture exists but no helper yet)
  - Stage the already-written `test_params` helper

### Fixture context

- `test/fixtures/files/cancellation_pre_uncancellation.json` — a `CANCELLATION` with `expiration_at_ms` only ~4 minutes in the future; used as the setup state (subscription is soft-cancelled/still active) before an uncancellation fires
- `test/fixtures/files/uncancellation.json` — the `UNCANCELLATION` event payload
