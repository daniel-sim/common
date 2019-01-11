class AddChargedAtToUsers < ActiveRecord::Migration[5.0]
  def change
    return if column_exists? :users, :charged_at

    add_column :users, :charged_at, :datetime
  end
end
