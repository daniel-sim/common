class CommonAddPeriodsPaidToTimePeriods < ActiveRecord::Migration[5.0]
  def change
    add_column :time_periods, :periods_paid, :integer, default: 0, null: false
  end
end
