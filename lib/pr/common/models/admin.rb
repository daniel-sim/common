require "devise"

module PR
  module Common
    module Models
      class Admin < ApplicationRecord
        extend Devise::Models
        devise :database_authenticatable, :validatable, :rememberable

        self.table_name = "admins"

        has_many :promo_codes,
                 class_name: "PR::Common::Models::PromoCode",
                 inverse_of: :created_by,
                 foreign_key: :created_by_id
      end
    end
  end
end
