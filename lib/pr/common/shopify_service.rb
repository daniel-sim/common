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
        plan_name = maybe_fake_plan_name(@shop, plan_name)

        if @shop.plan_name != plan_name && @shop.plan_name == "affiliate"
          # development shop now on a paid plan
          @user.update(active_charge: false)
          Analytics.track({
                              user_id: @user.id,
                              event: 'Shop Handed Off',
                              properties: {
                                  plan_name: plan_name,
                                  email: @user.email
                              }
                          })
        end
        @shop.update(plan_name: plan_name, uninstalled: uninstalled)
      end

      def set_uninstalled
        Analytics.track({
                            user_id: @user.id,
                            event: 'App Uninstalled',
                            properties: {
                                activeCharge: @user.has_active_charge?,
                                email: @user.email,
                                subscription_length: @user.subscription_length
                            }
                        })
        @user.update(active_charge: false)
        @shop.update(uninstalled: true)
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
              update_shop(plan_name: 'frozen', uninstalled: false)
            elsif e.response.code.to_s == '404'
              update_shop(plan_name: 'cancelled', uninstalled: false)
            elsif e.response.code.to_s == '420'
              update_shop(plan_name: '🌲', uninstalled: false)
            elsif e.response.code.to_s == '423'
              update_shop(plan_name: 'locked', uninstalled: false)
            end
          end
        end
        ShopifyAPI::Base.clear_session
      end

      def determine_price(plan_name: @shop.plan_name)
        # List prices in ascending order in config
        pricing = PR::Common.config.pricing

        best_price = pricing.last

        pricing.each do |price|
          if price[:plan_name] == plan_name
            best_price = price
          end
        end

        return best_price
      end

      private

      # Use this to fake different plans outside of production.
      # This allows us to test under development stores free of charge.
      # Normally, dev stores are always affiliates.
      # To fake a plan, name your shop something ending with "_plan-#{the_plan_name}"
      # e.g. "hello-ladies_plan-staff_business.myshopify.com"
      def maybe_fake_plan_name(shop, real_plan_name)
        return real_plan_name if Rails.env.production?

        shop.shopify_domain.match(/\A.*_plan-(?<plan>\w+)\./) { |matches| return matches[:plan] }

        real_plan_name
      end
    end
  end
end
