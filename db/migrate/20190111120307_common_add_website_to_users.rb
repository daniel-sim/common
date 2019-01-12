class CommonAddWebsiteToUsers < ActiveRecord::Migration[5.0]
  def change
    return if column_exists? :users, :website

    add_column :users, :website, :string, null: false
  end
end
