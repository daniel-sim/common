class AppUninstalledJob < PR::Common::ApplicationJob
  def perform(params)
    with_analytics do
      shop = Shop.find_by(shopify_domain: params[:shop_domain])

      PR::Common::ShopifyService
        .new(shop: shop)
        .update_shop(plan_name: shop.plan_name, uninstalled: true)
    end
  end
end
