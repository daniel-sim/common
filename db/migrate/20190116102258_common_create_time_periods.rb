class CommonCreateTimePeriods < ActiveRecord::Migration[5.2]
  def change
    create_table :time_periods do |t|
      t.column :start_time, :datetime, null: false, default: -> { "NOW()" }, index: true
      t.column :end_time, :datetime, index: true
      t.integer :kind, default: 0, null: false, index: true
      t.boolean :shop_retained_analytic_sent_at, index: true
      t.belongs_to :shop, index: true

      t.timestamps
    end
  end
end
