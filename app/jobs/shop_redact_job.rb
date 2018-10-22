class ShopRedactJob < PR::Common::ApplicationJob
  # PII should be removed from the shop,
  # user, and customers (if stored).
  # example payload:
  # {
  #   "shop_id": 954889,
  #   "shop_domain": "snowdevil.myshopify.com"
  # }
  def perform(params)
    shop = Shop.find_by(shopify_domain: params[:shop_domain])

    return unless shop

    shop.redact!
  end
end
