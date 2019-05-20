class CommonAddValueToPromoCodes < ActiveRecord::Migration[5.0]
  def change
    add_column :promo_codes, :value, :decimal, precision: 5, scale: 2, default: 100.0, null: false
  end
end
