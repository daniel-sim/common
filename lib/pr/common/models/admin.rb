require "devise"

module PR
  module Common
    module Models
      class Admin < ApplicationRecord
        extend Devise::Models
        devise :database_authenticatable, :validatable, :rememberable

        self.table_name = "admins"
      end
    end
  end
end
