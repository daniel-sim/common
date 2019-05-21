## 21 May 2019 (bd44a509e0a2f37e56f968078dff4c149568e163)
- Add validation to promo codes at login screen
- ! Apps require no changes

## 21 May 2019 (020285bc8d03a4467d297772c52f0ce6679d0505)
- Add `promo_code` support to ref links; e.g. "https://api.pluginseo.com?ref=REFERRER&promo_code=THE_CODE"
- ! Apps require no changes

## 21 May 2019 (b115021b804916fee346680c1817a186d7ab69be)
- Add expires_at to promo codes
- ! Apps require no changes

## 20 May 2019 (9de6705ada466a187fada8a4da53eb6c52268ad1)
- Add tracking against promo codes
- Add new SignInService with #track method for sending tracking analytics at sign in

- ! Apps require changes:

- In `app/controllers/shopify_app/sessions_controller.rb` add this to `#callback` just before
the redirect:

```
PR::Common::SignInService.track(model_shop)
```

- In `app/controllers/shopify_app/sessions_controller.rb` change the `@user =...` line in `#callback`:

```
@user = model_shop.user || model_shop.reload.user
```

## 20 May 2019 (9afaf30c719e2dca94a15673e66760cdbd377fae)
- Add `Shop#installed?` as inverse of `#uninstalled?`
- Promo codes are now removed from a shop if it's re-installing.
New, valid promo codes are still applied.

- ! Apps require changes:

- In `shopify_app/sessions_controller.rb` in the `#callback` method, change: 
```
maybe_apply_promo_code(model_shop)
```
To:

```
maybe_reconcile_promo_codes(model_shop)
```

## 16 May 2019 (511ada3661a09a932278ba2e5a109f7968a6dcb8 )
- Use promo code attached to shop when sending user to charges
- ! Apps require no changes

## 16 May 2019 (abcbd00c7216d9029473ce4b442e43a3fe87fd5e)
- Apply promo codes entered at login to a shop
- Display promo code errors at login if given

- ! Apps require changes:

- In the `shopify_app/sessions_controller.rb`:
  - add `include PR::Common::PromoCodes`
  - in the `callback` method, after we have the `model_shop`, add:`maybe_apply_promo_code(model_shop)`
  - add a `create` method if one doesn't exist / modify with this contnet:
    ```
    def create
      maybe_store_promo_code

      super unless performed?
    end
    ```

## 15 May 2019 (6d038bee4905e197060aa7c34e2649fe9f47321c)
- Copy newest ShopifyApp login page into common
- Add promo_code field to login page

- ! Apps require changes:
- Add this into  config/application.rb so that apps will pick up ShopifyApp overrides in
common before loading the ShopifyApp fallback:

```
# Load PR::Common::Engine just after main app and before other engines,
# so that we can override other engines as a priority in common
config.railties_order = [:main_app, PR::Common::Engine, :all]
```

## 15 May 2019 (e38b32d9238b02a1554b91399aa31f3c6903fc14)
- Add `created_by` for promo codes, which links to the admin that created it.
- ! Apps require no changes

## 14 May 2019 (c9ed3b00f72aa2ad01bd4b1fb237ee8cac82c519)
- Add basic admin form for creating promo codes
- ! Apps require no changes

## 14 May 2019 (ab4ec6090886cc889304dd498ee98c73a5d53379)
- Implement new /admin namespace with Admin model
- ! Apps require no changes

## 14 May 2019 (a08789e536fce7f5754216976a6fb34f893ebd84)
- Remove old admin routes
- ! Apps require no changes

## 14 May 2019 (7a44cd86659884b8c61f757e8316b38c7ebc48a6)
- Add promo codes model
- ! Apps require no changes

## 13 May 2019 (c2156c5ab37efab4e2b18434652b67450e4387a6)
- Add ShopifyService#remote_shop
- Bring in ShopifyErrors for error handling
- ! Apps require no changes

## 25 April 2019 (4c46f1ce1870dc5c62f6665bcaed8a530daf7c5e)
- Fix bug in which recreating webhooks for existing shops would delete any existing webhooks that should be there.
- ! Apps require no changes

## 12 April 2019 (35837fcaab5cbeb6a2bbe6228d68e604d006b580)
- Add "email" trait to all identify analytics. This is required by Drip.
- ! Apps require no changes

## 10 April 2019 (cb8e5ec7204a04b5d0570f7eda67c0c2e20d7ad4)
- ShopifyService#update_shop can now update any of Shop's attributes.
- ! Apps require no changes

## 10 April 2019 (59b4ebdd2c5783ea8e1f460a291cf779187f0f39)
- `Shop` now has the following new methods:
  - active?
  - inactive?
  - active_plan?
  - inactive_plan?
- ! Apps require no changes

## 27 March 2019 (96fbd14a777f0ec91e12bed39082e9dcd5122bdf)
- `active_charge` is no longer set to true on shop handoff
- ! Apps require no changes

## 27 March 2019 (efe6f6c2f92fc696d3924f1494b374c487d7097e)
- activeCharge and trial are now sent in the `identify` analytics call after reinstall
- ! Apps require no changes

## 26 March 2019 (9480dfe787564f8dd49940897e4f03f9909ee91b)
- Shop reconciliation now handles 403 errors as fraudulent
- ! Apps require no changes

## 26 March 2019 (dd7607310e56dd7d16c174d216e1d71630d2cfdf)
- Shop reconciliation will now create a user if one does not exist.
  There are edge cases in which users never get created for shops.
  Since a user can only be created with an email, it first needs to be able
  to retrieve the shop from Shopify.
- ! Apps require no changes

## 21 March 2019 (0b1327a97ad41bb996a91bfbf00dc3f5423ca16e)
- Fix issue with the price history importer failing if a "Billing Period End"
  cell is empty.
- ! Apps require no changes

## 20 March 2019 (147ffe023e6772a4a49d7c081f75a2dc9568bfcd)
- Fix callback on shops creating an additional `installed` time period.
  This will only happen now if no other time period exists.
- ! Apps require no changes

## 14 March 2019 (095e523892605552f40c9a03c25b5f0188761cda)
- Add `pricing_method` to PR::Common::Configuration.
  By setting it to a lambda, apps can have their own pricing rules,
  independent of plan names.
- ! Apps require no changes

## 1 February 2019 (a4be13cb19baef8391dfce4e00ecafcd6ca99335)
- When a shop is retrieved from the DB, reconcile its time periods if
  no time periods exist.
  This prevents any NoMethodErrors on nil happening for pre-existing shops.
- ! Apps require no changes

## 1 February 2019 (d13c348a8b78eefa2229db36245259e6a04f9f55)
- When a shop reinstalls, its identify analytic will now include `monthlyUsd`.
  Since it is not copied from a previous time period, it is always 0.
- ! Apps require no changes

## 29 January 2019 (9387396b1692d49eb4f499e9fabf9a3734bc15ce)
- When a new time period is created automatically in a shop,
  copy over some attributes of the previous one conditionally.
- ! Apps require no changes

## 29 January 2019 (c98ca261942e3478de838feaa22ecd8c1a967c70)
- `SustainedAnalyticsService` now takes an optional `current_time` which
  will be used as the "current time" across the service.
- Various other methods take a `current_time` now.
- ! Apps require no changes, but `SustainedAnalyticsJob` should not be scheduled
  more frequently than hourly.

## 28 January 2019 (f0239b5fdb4bc6f30532e4296b485e0b10f3a8a6)
- Reset shop `app_plan` when reinstalling
- Made various ShopifyService methods private
- ! Apps require no changes

## 28 January 2019 (8d387a6b5acba401405d8e934d67c244ea5883c1)
- `charged_at` of user is now set to the current time when shop is reopened
- ! Apps require no changes

## 25 January 2019 (4f8b8f4c6b30bb81c2eef8faa89914875b61f8c5)
- Add a `default_app_plan` setting to config
- ! Shops that have a default plan with no pricing should set the `default_app_plan`
  in the common initializer

## 24 January 2019 (86ab3300f4cd899674b1c481e2d5242058e65580)
- Add `appPlan` to identify analytics on install and reinstall
- ! Apps require no changes

## 24 January 2019 (66543d0b69d4d52e4200e1676b43b198012e66d2)
- Add `shopify_plan` to various installation analytics
- ! Apps require no changes

## 23 January 2019 (d8b93623d6c5994dad2ef7de466564c1e8eff0b1)
- Fix duplicate analytics, "App Reinstalled", "Shop Closed"
- ! Apps require no changes

## 23 January 2019 (988e1fa554ccdd09ff4886baee11cec8d2cdf76d)
- Add "Shopify Plan Updated" analytic which sends both an identify and a track from
  `ShopifyService#update_shop` when shopify plan changes. Will not send if shopify plan is not
  already set to something.
- ! Apps require no changes

## 23 January 2019 (be512725f9b7cb4af2d31abbb4de476d33fcea8d)
- Add `trial` to `identify` analytics when charge activated and converted to paid
- ! Apps require no changes

## 22 January 2019 (768c1d3639eb0a2b73663edc17a5a1dd730c0a3f)
- Add `Shop.status`
- Add `appPlan` and `app_plan` to Charge Activated analytic
- Send along `status` with various identify analytics
- ! Apps require no changes

## 22 January 2019 (08962f586dec1396c5b2f68e34616fb856809090)
- Clean up various analytics, add more identify traits
- ! Apps require no changes

## 22 January 2019 (a9f0a80bc55d222256804efdc41ca4219a43ba21)
- Renamed `plan_name` to `shopify_plan` everywhere.
- ! Apps need to replace `plan_name` with `shopify_plan` in most references.
  ! Be very careful when dealing with webhook params and the Shopify API: these will
    **still use `plan_name`**
- ! Apps need to *ensure* that in `shopify_app/sessions_controller.rb`, the `callback`
    method calls this:
    ```
    shopify_service = PR::Common::ShopifyService.new(shop: model_shop)
    shopify_service.update_shop(shopify_plan: api_shop.plan_name, uninstalled: false)
    ```
    BEFORE this:
    ```
    user_service = PR::Common::UserService.new
    @user = user_service.find_or_create_user_by_shopify(email: api_shop.email, shop: model_shop, referrer: request.env['affiliate.tag'])
    ```
    Otherwise, `shopify_plan` is not set when the user service sends an installed analytic

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
