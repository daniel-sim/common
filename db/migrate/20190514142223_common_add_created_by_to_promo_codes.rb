class CommonAddCreatedByToPromoCodes < ActiveRecord::Migration[5.0]
  def change
    add_reference :promo_codes, :created_by
  end
end
