class CommonAddNoBrainerIndices < ActiveRecord::Migration[5.0]
  def change
    unless ActiveRecord::Base.connection.index_exists?(:shops, :shopify_domain)
      add_index :shops, :shopify_domain
    end

    unless ActiveRecord::Base.connection.index_exists?(:users, :username)
      add_index :users, :username
    end

    unless ActiveRecord::Base.connection.index_exists?(:users, :provider)
      add_index :users, :provider
    end
  end
end
