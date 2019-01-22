class CommonChangePlanNameToShopifyPlanOnShops < ActiveRecord::Migration[5.0]
  def change
    rename_column :shops, :plan_name, :shopify_plan
  end
end
