module Shopify
  module Webhooks
    class AppUninstalledJob < PR::Common::ApplicationJob
      def perform(shop_domain:, webhook: nil)
        with_analytics do
          shop = Shop.find_by(shopify_domain: shop_domain)

          PR::Common::ShopifyService
            .new(shop: shop)
            .update_shop(shopify_plan: shop.shopify_plan, uninstalled: true)
        end
      end
    end
  end
end
