class CommonAddConvertedToPaidAddToTimePeriod < ActiveRecord::Migration[5.0]
  def change
    add_column :time_periods, :converted_to_paid_at, :datetime
    add_index :time_periods, :converted_to_paid_at
  end
end
