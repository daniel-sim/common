require_relative 'application_job'

class ShopUpdateReconcileJob < PR::Common::ApplicationJob
  queue_as :low_priority

  def perform(shop)
    shopify_service = PR::Common::ShopifyService.new(shop: shop)
    shopify_service.reconcile_with_shopify
  end
end
