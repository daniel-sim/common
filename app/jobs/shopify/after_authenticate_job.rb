module Shopify
  class AfterAuthenticateJob < PR::Common::ApplicationJob
    def perform(options = {})
      shop_domain = options[:shop_domain] || raise("Shop domain missing")

      with_analytics do
        shop = Shop.find_by(shopify_domain: shop_domain)

        shop.with_shopify_session do
          api_shop = ShopifyAPI::Shop.current

          ensure_shop_has_user(api_shop, shop, options)
          ensure_shop_installed(shop, api_shop.plan_name)
          track_login(shop)
        end
      end
    end

    private

    # Not all shops have users (legacy)
    def ensure_shop_has_user(api_shop, shop, options)
      PR::Common::UserService.new.find_or_create_user_by_shopify(
        email: api_shop.email,
        shop: shop,
        referrer: options[:referrer]
      )

      shop.reload
    end

    # they're logging in so must be installed
    def ensure_shop_installed(shop, shopify_plan)
      shopify_service = PR::Common::ShopifyService.new(shop: shop)
      shopify_service.update_shop(shopify_plan: shopify_plan, uninstalled: false)
    end

    def track_login(shop)
      PR::Common::SignInService.track(shop)
    end
  end
end
