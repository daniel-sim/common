module PR
  module Common
    module Models
      class PromoCode < ApplicationRecord
        self.table_name = "promo_codes"

        has_many :shops, class_name: "::Shop"

        validates :code, uniqueness: true, presence: true
        before_save :upcase_code

        def redeemable?
          return true

          # TODO: extend with what makes promo codes valid later (e.g. expiry)
        end

        private

        def upcase_code
          code.upcase!
        end
      end
    end
  end
end
