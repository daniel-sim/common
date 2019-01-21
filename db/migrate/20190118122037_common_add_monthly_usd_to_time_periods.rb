class CommonAddMonthlyUsdToTimePeriods < ActiveRecord::Migration[5.0]
  def change
    add_column :time_periods, :monthly_usd, :decimal, default: 0, null: false
  end
end
