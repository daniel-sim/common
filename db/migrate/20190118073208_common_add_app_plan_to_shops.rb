class CommonAddAppPlanToShops< ActiveRecord::Migration[5.0]
  def change
    add_column :shops, :app_plan, :string
    add_index :shops, :app_plan
  end
end
