module PR
  module Common
    module Models
      # This is a stake in the ground to gradually improve our messy User code
      # As much as possible should be in Common
      # We will work towards this by including this module in our apps and moving generic pieces here
      # So please include PR::Common::Models::User
      module User
        extend ActiveSupport::Concern

        included do
          delegate :just_reinstalled?, to: :shop
          delegate :just_reopened?, to: :shop

          enum provider: { shopify: 0, tictail: 1 }

          [:has_active_charge?, :active_charge?].each do |name|
            send(:define_method, name, -> { self.active_charge })
          end

          def subscription_length
            return if charged_at.blank?

            (DateTime.now - self.charged_at.to_datetime).to_i
          end
        end

        class_methods do
          # add class methods here
        end

        # Legacy
        # can't unfortunately put this as a has_one
        # because ShopifyApp::SessionsController creates the Shop before a User
        def shop
          return unless shopify?

          if shop_id.blank?
            shop = ::Shop.find_by(shopify_domain: username.slice("shopify-"))
            self.shop = shop
          end

          ::Shop.find_by(id: shop_id)
        end

        def shop=(shop)
          self.shop_id = shop.id
          save!
        end
      end
    end
  end
end
