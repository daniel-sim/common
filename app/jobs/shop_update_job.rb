class ShopUpdateJob < PR::Common::ApplicationJob
  def perform(params)
    with_analytics do
      shop = Shop.find_by(shopify_domain: params[:shop_domain])
      shopify_service = PR::Common::ShopifyService.new(shop: shop)
      shopify_service.update_shop(shopify_plan: params[:webhook][:plan_name], uninstalled: false)
      shopify_service.update_user(email: params[:webhook][:email])
    end
  end
end
