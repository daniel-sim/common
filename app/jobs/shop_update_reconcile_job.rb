class ShopUpdateReconcileJob < PR::Common::ApplicationJob
  queue_as :low_priority

  def perform(shop)
    with_analytics do
      shopify_service = PR::Common::ShopifyService.new(shop: shop)
      shopify_service.reconcile_with_shopify
    end
  end
end
