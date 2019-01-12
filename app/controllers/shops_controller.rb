class ShopsController < ApplicationController
  def callback
    shop = Shop.find_by(shopify_domain: params[:myshopify_domain])
    shop.update!(shop_params)

    return unless shop.just_cancelled?

    ShopifyService.new(shop: shop).track_cancelled
  end

  private

  def shop_params
    params.permit(:plan_name)
  end
end
