module PR
  module Common
    class UserService
      def find_or_create_user_by_shopify(email:, shop:, referrer: nil)
        find_shopify_user(shop: shop, referrer: referrer) ||
          create_shopify_user(email: email, shop: shop, referrer: referrer)
      end

      private

      def create_shopify_user(email:, shop:, referrer:)
        Rails.logger.info("create_shopify_user for email #{email}, shop #{shop.id}")

        user = User.create(
          username: "shopify-#{shop.shopify_domain}",
          password: SecureRandom.hex,
          provider: "shopify",
          website: shop.shopify_domain,
          shop_id: shop.id,
          email: email,
          referrer: referrer
        )

        Rails.logger.info("create_shopify_user created: #{user.present?}, id: #{user&.id}")

        identify(user, referrer)
        track_install(user)

        user
      end

      def find_shopify_user(shop:, referrer:)
        user = User.find_by(username: "shopify-#{shop.shopify_domain}", provider: "shopify")

        user || return
        return unless user

        identify(user, referrer)

        user
      end

      def identify(user, referrer)
        Analytics.identify(
          user_id: user.id,
          traits: {
            primaryDomain: user.shop.shopify_domain,
            email: user.email,
            product: "Shopify",
            username: user.username,
            activeCharge: user.active_charge,
            shopifyPlan: user.shop.shopify_plan,
            referrer: referrer
          }
        )
      end

      def track_install(user)
        ShopifyService.new(shop: user.shop).track_installed
      end
    end
  end
end
