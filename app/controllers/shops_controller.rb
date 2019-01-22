class ShopsController < ApplicationController
  def callback
    shop = Shop.find_by(shopify_domain: params[:myshopify_domain])

    PR::Common::ShopifyService
      .new(shop: shop)
      .update_shop(shopify_plan: shop_params[:plan_name], uninstalled: shop.uninstalled)
  end

  private

  def shop_params
    params.permit(:plan_name)
  end
end
