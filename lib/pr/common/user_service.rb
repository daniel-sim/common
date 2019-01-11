module PR
  module Common
    class UserService
      INSTALLED_EVENT = "App Installed".freeze
      REINSTALLED_EVENT = "App Reinstalled".freeze

      def find_or_create_user_by_shopify(email:, shop:, referrer: nil)
        if user = User.find_by(username: "shopify-#{shop.shopify_domain}", provider: "shopify")
          Analytics.identify(
            user_id: user.id,
            traits: {
              primaryDomain: shop.shopify_domain,
              email: email,
              product: "Shopify",
              username: user.username,
              activeCharge: user.active_charge
            }
          )

          maybe_track_user_reinstalled(user)

          user
        else
          created_user = User.create(
            username: "shopify-#{shop.shopify_domain}",
            password: SecureRandom.hex,
            provider: "shopify",
            website: shop.shopify_domain,
            shop_id: shop.id,
            email: email,
            referrer: referrer
          )

          Analytics.identify(
            user_id: created_user.id,
            traits: {
              primaryDomain: shop.shopify_domain,
              email: email,
              product: "Shopify",
              username: created_user.username,
              activeCharge: created_user.active_charge,
              referrer: referrer
            }
          )

          track_user_installed(created_user, INSTALLED_EVENT)

          created_user
        end
      end

      private

      def maybe_track_user_reinstalled(user)
        return unless user.just_reinstalled?

        track_user_installed(user, REINSTALLED_EVENT)
      end

      def track_user_installed(user, event)
        Analytics.track(
          user_id: user.id,
          event: event,
          properties: {
            "registration method": "shopify",
            "email": user.email
          }
        )
      end
    end
  end
end
