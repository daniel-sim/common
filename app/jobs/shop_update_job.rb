class ShopUpdateJob < PR::Common::ApplicationJob
  def perform(params)
    with_analitics do
      shop = Shop.find_by(shopify_domain: params[:shop_domain])
      shopify_service = PR::Common::ShopifyService.new(shop: shop)
      shopify_service.update_shop(plan_name: params[:webhook][:plan_name], uninstalled: false)
      shopify_service.update_user(email: params[:webhook][:email])
    end
  end
end
