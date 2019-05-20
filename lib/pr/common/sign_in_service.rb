module PR
  module Common
    # Generic sign in service. To be filled out further later
    module SignInService
      def self.track(shop)
        Rails.logger.info "Shop signed in. shop_id=#{shop.id}"
        user = shop.user
        properties = { email: user.email, promo_code: shop.promo_code&.code }

        Analytics.identify(user_id: user.id, traits: properties)
        Analytics.track(user_id: user.id, event: "Shop Signed In", properties: properties)
      end
    end
  end
end
