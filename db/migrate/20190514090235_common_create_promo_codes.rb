class CommonCreatePromoCodes < ActiveRecord::Migration[5.0]
  def change
    create_table :promo_codes do |t|
      t.column :code, :string, null: false, unique: true, index: true
      t.column :description, :string

      t.timestamps
    end
  end
end
