class CommonAddPromoCodeToShops < ActiveRecord::Migration[5.0]
  def change
    add_reference :shops, :promo_code
  end
end
