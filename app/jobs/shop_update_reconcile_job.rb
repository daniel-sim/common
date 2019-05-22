class ShopUpdateReconcileJob < PR::Common::ApplicationJob
  queue_as :low_priority

  def self.enqueue
    Shop.installed.with_active_plan.pluck(:id).each(&method(:perform_later))
  end

  def perform(shop_id)
    # Set this back to the beginning of the hour to ensure that scheduled jobs
    # run at "exactly" the same time each day.
    current_time = Time.current.beginning_of_hour

    with_analytics do
      shop = Shop.find(shop_id)

      logger.info "Reconciling shop #{shop.shopify_domain}"
      reconciled = PR::Common::ShopifyService.new(shop: shop).reconcile_with_shopify

      logger.info "Failed to reconcile shop #{shop.shopify_domain}" unless reconciled

      if shop.uninstalled

        logger.info "Reconciling shop #{shop.shopify_domain} found it uninstalled; "\
                    "will not proceed"

        return
      end

      logger.info "Recording sustained analytics for shop #{shop.shopify_domain}"

      PR::Common::SustainedAnalyticsService.new(shop, current_time: current_time).perform
    end
  end
end
