class CommonChangePlanNameToShopifyPlanOnShops < ActiveRecord::Migration[5.2]
  def change
    rename_column :shops, :plan_name, :shopify_plan
  end
end
