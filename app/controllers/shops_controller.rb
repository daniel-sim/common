class ShopsController < ApplicationController
  def callback
    shop = Shop.find_by(shopify_domain: shop_params[:myshopify_domain])

    PR::Common::ShopifyService
      .new(shop: shop)
      .update_shop(shopify_plan: shop_params[:plan_name], uninstalled: shop.uninstalled)
  end

  private

  def shop_params
    params.permit(:myshopify_domain, :plan_name)
  end
end
