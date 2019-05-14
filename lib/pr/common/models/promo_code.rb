module PR
  module Common
    module Models
      class PromoCode < ApplicationRecord
        self.table_name = "promo_codes"

        def self.model_name
          ActiveModel::Name.new(self, nil, "PromoCode")
        end

        has_many :shops, class_name: "::Shop"

        validates :code, uniqueness: true, presence: true
        validates :value, numericality: { greater_than_or_equal_to: 0 }
        before_validation :upcase_code

        private

        def upcase_code
          code&.upcase!
        end
      end
    end
  end
end
