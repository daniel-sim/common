module PR
  module Common
    class ShopifyService
      def initialize(shop:)
        @shop = shop
        @user = User.shopify.find_by(shop_id: @shop.id)
      end

      def update_user(email:)
        @user.update(email: email)
      end

      def update_shop(plan_name:, uninstalled:)
        return @shop.update(uninstalled: uninstalled) if @shop.plan_name == plan_name

        update_shop_with_new_plan(plan_name, uninstalled: uninstalled)
      end

      def update_shop_with_new_plan(new_shop_plan, uninstalled:)
        if @shop.plan_name == Shop::PLAN_AFFILIATE
          # development shop moved to another plan
          @user.update(active_charge: false)
          track_handed_off(new_shop_plan)
        elsif new_shop_plan == Shop::PLAN_CANCELLED && !@shop.cancelled_or_frozen?
          track_cancelled
        end

        @shop.update(plan_name: new_shop_plan, uninstalled: uninstalled)
      end

      def set_uninstalled
        if @user.present?
          Analytics.track(
            user_id: @user.id,
            event: "App Uninstalled",
            properties: {
              activeCharge: @user.has_active_charge?,
              email: @user.email,
              subscription_length: @user.subscription_length
            }
          )
          @user.update(active_charge: false)
        end

        @shop.update(uninstalled: true)
      end

      def track_handed_off(new_shop_plan)
        Analytics.track(
          user_id: @user.id,
          event: "Shop Handed Off",
          properties: {
            plan_name: new_shop_plan,
            email: @user.email
          }
        )
      end

      def track_cancelled
        Analytics.track(
          user_id: @user.id,
          event: "Shop Closed",
          properties: {
            subscription_length: @user.subscription_length
          }
        )
      end

      def reconcile_with_shopify
        ShopifyAPI::Session.temp(@shop.shopify_domain, @shop.shopify_token) do
          begin
            shopify_shop = ShopifyAPI::Shop.current
            update_shop(plan_name: shopify_shop.plan_name, uninstalled: false)
          rescue ActiveResource::UnauthorizedAccess => e
            # we no longer have access to the shop- app uninstalled
            set_uninstalled
          rescue ActiveResource::ClientError => e
            if e.response.code.to_s == '402'
              update_shop(plan_name: Shop::PLAN_FROZEN, uninstalled: false)
            elsif e.response.code.to_s == '404'
              update_shop(plan_name: Shop::PLAN_CANCELLED, uninstalled: false)
            elsif e.response.code.to_s == '420'
              update_shop(plan_name: '🌲', uninstalled: false)
            elsif e.response.code.to_s == '423'
              update_shop(plan_name: Shop::PLAN_LOCKED, uninstalled: false)
            end
          end
          ShopifyAPI::Base.clear_session
        end
      end

      def determine_price(plan_name: @shop.plan_name)
        # List prices in ascending order in config
        pricing = PR::Common.config.pricing

        best_price = pricing.last

        pricing.each do |price|
          best_price = price if price[:plan_name] == plan_name
        end

        best_price
      end
    end
  end
end
