### 12 January 2019 (d23dbcccb3ff863ca913f7c4751be19d5f21ff5f)
- Added `reopened_at` to Shop
- When Shop goes from `frozen` or `cancelled` to a different plan name, `reopened_at` is set
  to the current timestamp and an analytic is sent
- ! Apps require no changes

### 11 January 2019 (2310b2e8bc091e1af6928a347d00f5904456f94b)
- Fixed migration for adding charged_at to users
- Added migration to add username to users; this should already be present in apps
- Added migration to add website to users; this should already be present in apps
- Made `Shop#just_reinstalled?` public, also accessible via `User` now
- Set `has_one :user` on Shop
- Added `shop` and `shop=` methods to User
- Slightly refactored of `UserService`
- Added "App Reinstalled" analytic to `UserService`
- Added specs for `UserService`


- ! Apps require no changes, but should do the following:

- Ensure that migrations work fine after update
- Ensure that getting and setting a shop on a user still works well
- Remove `has_one :user` from `Shop` if present
- Remove `shop` and `shop=` methods on `User` if present

### 10 January 2019 (555d22b733e1f02c536fa0fe6dca1a5fbfd77133)
- Remove BitBucket pipeline config
- Add CircleCI config
- Add CodeClimate config
- Add RuboCop config
- ! Apps require no changes.

### 4 December 2018 (f4b98f3537ba63932cb8594fd18d56db80c97087)
- Add `reinstalled_at` to shops. This is automatically tracked when setting `uninstalled` to false.
- ! Apps require no changes.

### 19 November 2018 (2f485701b932580bd4995fe4cab199caf8e23094)
- Remove Rollbar scoping on Shopify requests as it altered global scope every time
- ! Apps require no changes.

### 5 November 2018 (9cb76ca9fc05643d4fe8f08788cabf11a0587849)
- Fixed issue where each call to ActiveResource would add another set of arguments to Rollbar scope, resulting in a huge error if one ever occurs.
- ! Apps require no changes.

### 30 Oct 2018 (bc0c8c8763c8c251036a0ab5257dec30dfe6c8cf)
- BUGFIX: Do not expect a shop to have a user when uninstalling via the reconcile job
! Does not require any action in apps

### 26 Oct 2018 (01075dbba74fc767558c530f9768aa606080d245)

- BUGFIX: Added Analytics.flush to sidekiq jobs
! Does not require any action in apps

### 25 Oct 2018

- Added Analytics to initializers
! Now you can remove analytics initializer from apps

- Update shop.plan_name in reconcile job
! Does not require any action in apps
