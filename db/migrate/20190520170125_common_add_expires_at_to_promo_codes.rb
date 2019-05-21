class CommonAddExpiresAtToPromoCodes < ActiveRecord::Migration[5.0]
  def change
    add_column :promo_codes, :expires_at, :timestamp
  end
end
