class CommonRemoveReinstalledAtAndReopenedAtFromShops < ActiveRecord::Migration[5.0]
  def change
    remove_column :shops, :reinstalled_at, :timestamp
    remove_column :shops, :reopened_at, :timestamp
  end
end
