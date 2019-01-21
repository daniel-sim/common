class ShopUpdateReconcileJob < PR::Common::ApplicationJob
  queue_as :low_priority

  def self.enqueue
    Shop.where(uninstalled: false).pluck(:id).each(&method(:perform_later))
  end

  def perform(shop_id)
    with_analytics do
      shop = Shop.find(shop_id)

      logger.info "Reconciling shop #{shop.shopify_domain}"
      reconciled = PR::Common::ShopifyService.new(shop: shop).reconcile_with_shopify

      logger.info "Failed to reconcile shop #{shop.shopify_domain}" unless reconciled

      if shop.uninstalled

        logger.info "Reconciling shop #{shop.shopify_domain} found it uninstalled; "\
                    "will not proceed"
      end

      return if shop.uninstalled

      logger.info "Recording sustained analytics for shop #{shop.shopify_domain}"

      PR::Common::SustainedAnalyticsService.new(shop).perform
    end
  end
end
