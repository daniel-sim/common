require_relative 'application_job'

class ShopUpdateJob < PR::Common::ApplicationJob
  def perform(params)
    shop = Shop.find_by(shopify_domain: params[:shop_domain])
    shopify_service = PR::Common::ShopifyService.new(shop: shop)
    shopify_service.update_shop(plan_name: params[:webhook]['plan_name'], uninstalled: false)
  end
end
