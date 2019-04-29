module Shopify
  module Webhooks
    class ShopUpdateJob < PR::Common::ApplicationJob
      def perform(shop_domain:, webhook:)
        with_analytics do
          shop = Shop.find_by(shopify_domain: shop_domain)

          # ensure we have a user
          PR::Common::UserService
            .new
            .find_or_create_user_by_shopify(email: webhook[:email], shop: shop)

          shopify_service = PR::Common::ShopifyService.new(shop: shop)
          shopify_service.update_shop(shopify_plan: webhook[:plan_name], uninstalled: false)
          shopify_service.update_user(email: webhook[:email])
        end
      end
    end
  end
end
