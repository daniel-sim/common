class AddReinstalledAtToShops < ActiveRecord::Migration[5.2]
  def change
    return if column_exists? :shops, :reinstalled_at

    add_column :shops, :reinstalled_at, :timestamp
  end
end
