## 22 January 2019 (08962f586dec1396c5b2f68e34616fb856809090)
- Clean up various analytics, add more identify traits
- ! Apps require no changes
## 22 January 2019 (a9f0a80bc55d222256804efdc41ca4219a43ba21)
- Renamed `plan_name` to `shopify_plan` everywhere.
- ! Apps need to replace `plan_name` with `shopify_plan` in most references.
  ! Be very careful when dealing with webhook params and the Shopify API: these will
    **still use `plan_name`**

## 22 January 2019 (795f9db36936017ca3302bd802865ce1f0958931)
- Added `shopify_plan` to App Installed analytic
- Added `shopify_plan` to App Reinstalled analytic
- Added `shopify_plan` to Shop Reopened analytic
- ! Apps require no changes

## 22 January 2019 (9ae829c0ad21569728185fd4695e16c840c7062c)
- Added properties to App Uninstalled analytic
- Added properties to Shop Closed analytic
- ! Apps require no changes

## 22 January 2019 (fe27bdaaa36223887e3f3098b1807a7b60bb716d)
- Added `common:import:payment_history`
- ! Apps should run the above task with a CSV to set `period_last_paid_at`
  and `periods_paid` on active time periods, based on the last payment date,
  and send relevant analytics.

## 22 January 2019 (dfe5695c608853c2f85758973decea1499ed7f7f)
- Added `period_last_paid_at` and `periods_paid` to TimePeriod
- Added "Payment Charged" analytic to `SustainedAnalyticsService`
- ! Apps require no changes

## 21 January 2019 (35d34cb37553348c548f398d1bd59e1072c6846e)
- Improved ChargesService
- Fixed up ChargesController to work with ChargesService changes
- Dropped `common:schedule:sustained_analytics` in favour of
  `common:shops:reconcile`
- Added logging and SustainedAnalyticsService call to
  ShopUpdateReconcile job

- ! Apps require changes:

- Add a new symbol, `key` to each price in the common initializer. This is considered the "app_plan"
- Ensure that the names of each price in the common initializer are unique
- Remove `lib/tasks/shop_update_reconcile.rake`
- Replace `shop_update_reconcile` in schedule with:
  ```
  rake_with_lock 'common:shops:reconcile', output: "#{log_root}common-shops-reconcile.log", lock: "#{log_root}common-shops-reconcile.lock"
  ```

## 18 January 2019 (8f4525294988a8042e420b63eb5249baaa667ca3)
- Added `common:schedule:sustained_analytics` rake task. Task can be used to schedule `SustainedAnalyticsJob`.
- ! Apps should add this task to their schedule, potentially daily. For testing, consider running more often on staging.

## 18 January 2019 (9250966bbbd377cbe815e386a0548ae9be068e72)
- Add `SustainedAnalyticsService` and the thin wrapper, `SustainedAnalyticsJob`.
- Job currently runs through all shops with an in-use, not-yet-ended time period and may send a `"Shop Retained"` analytic.
- ! Apps require no changes

## 17 January 2019 (aa12c53046c9494db8533ac244d34ec8e4a5ed59)
- Add the aptly-named `TimePeriod#lapsed_days_since_last_shop_retained_analytic`. If `shop_retained_analytic_sent_at`
  is not set, it uses the time period's start time.
- ! Apps require no changes

## 17 January 2019 (45ced04d7dba4b9caa41eaba5d1320adec0bf282)
- Add `Shop#total_days_installed` which sums the lapsed days of every "in use" time period. An in-use
  time period is one in which the app is not uninstalled or closed, also scoped at `TimePeriod.whilst_in_use`
- Fix `TimePeriod.not_yet_ended` to use `Time.current` rather than DB time
- ! Apps require no changes

## 17 January 2019 (197f57d7a0ef5a4c6cc9dfcfb02defd2491e9238)
- Add `TimePeriod#lapsed_days` to determine number of days lapsed since a `TimePeriod` is created
- ! Apps require no changes

### 16 January 2019 (c2bc5b00adfc0bec93d124cdc6f2c3f4674fbe6b)
- Add `TimePeriod` model
- Every shop now has `TimePeriods`
- `TimePeriods` will be reconciled (created/modified if necessary) when a Shop is saved
- ! Apps should save each shop one time in order to ensure that each has a `TimePeriod`:
  ```
  Shop.find_each(&:save)
  ```

### 15 January 2019 (12e8df17a0837144bd77f800ca3b5dda5ed040e3)
- Fixes some previously defined analytics calls
- Normalizes analytics calls to one place (ShopifyService)
- ! Apps require no changes
-
### 12 January 2019 (7d216c97952dd3fe553ecafaac555741679dedf9)
- `charged_at` will now be cleared upon reinstall of the app or reopening of the shop
- `charged_at` and `charged_at=` are now delegated from shop -> user
- "Shop Closed" analytic is sent when plan_name of a shop goes to "cancelled" from a plan name that is not "cancelled" or "frozen".
- "Shop Closed" analytic is sent under both reconciliation and webhooks
- ! Apps require no changes

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
