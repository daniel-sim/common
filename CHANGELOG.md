### 19 November 2018 (2f485701b932580bd4995fe4cab199caf8e23094)
- Remove Rollbar scoping on Shopify requests as it altered global scope every time
- ! Apps require no changes.

### 5 November 2018 (9cb76ca9fc05643d4fe8f08788cabf11a0587849)
- Fixed issue where each call to ActiveResource would add another set of arguments to Rollbar scope, resulting in a huge error if one ever occurs.
- ! Apps require no changes.

### 31 Oct 2018 (20c0a4f33407f5a56b05c08a9ef1a438137e0719)
- Added GDPR webhooks
! Apps should add any additional revokable fields if there are any.

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
