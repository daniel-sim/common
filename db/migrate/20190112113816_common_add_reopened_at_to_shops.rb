class CommonAddReopenedAtToShops < ActiveRecord::Migration[5.0]
  def change
    add_column :shops, :reopened_at, :timestamp
  end
end
