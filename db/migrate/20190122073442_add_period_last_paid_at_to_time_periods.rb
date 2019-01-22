class AddPeriodLastPaidAtToTimePeriods < ActiveRecord::Migration[5.0]
  def change
    add_column :time_periods, :period_last_paid_at, :datetime
    add_index :time_periods, :period_last_paid_at
  end
end
