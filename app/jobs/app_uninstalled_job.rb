require_relative 'application_job'

class AppUninstalledJob < PR::Common::ApplicationJob
  def perform(params)
    # no need for a reconcile job for this webhook since shop_update will reconcile these (UnauthorizedAccess exception)
    shop = Shop.find_by(shopify_domain: params[:shop_domain])
    shopify_service = PR::Common::ShopifyService.new(shop: shop)
    shopify_service.set_uninstalled
  end
end
