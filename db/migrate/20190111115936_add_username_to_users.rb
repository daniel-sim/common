class AddUsernameToUsers < ActiveRecord::Migration[5.0]
  def change
    return if column_exists? :users, :username

    add_column :users, :username, :string, null: false
  end
end
