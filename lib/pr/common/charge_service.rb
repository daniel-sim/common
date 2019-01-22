module PR
  module Common
    class ChargeService
      def self.determine_app_plan_from_charge(charge)
        PR::Common.config.pricing.detect { |price| price[:name] == charge.name }&.[](:key)
      end

      def initialize(shop)
        @shop = shop
        @user = shop.user
      end

      def create_charge(price, base_url)
        ShopifyAPI::RecurringApplicationCharge.current&.cancel

        price.positive? ? create_nonfree_charge(base_url) : create_free_charge
      end

      def activate_charge(charge)
        app_plan = self.class.determine_app_plan_from_charge(charge)
        activate_user(app_plan, charge)

        charge
      end

      # Fetches plan name from shopify and determines price from it
      def up_to_date_price
        PR::Common::ShopifyService
          .new(shop: @shop)
          .determine_price(shopify_plan: api_shop.shopify_plan)
      end

      private

      def create_free_charge
        app_plan = PR::Common::ShopifyService
                   .new(shop: @shop)
                   .determine_price&.[](:key)

        @shop.update(app_plan: app_plan)

        activate_user(app_plan)
      end

      def create_nonfree_charge(base_url)
        ShopifyAPI::RecurringApplicationCharge
          .create(charge_params(base_url))
      end

      def charge_params(base_url)
        PR::Common::ShopifyService
          .new(shop: @shop)
          .determine_price(shopify_plan: api_shop.shopify_plan)
          .merge(test: !Rails.env.production?,
                 return_url: return_url(base_url))
          .except(:key)
      end

      def return_url(base_url)
        "#{base_url}#{Rails.application.routes.url_helpers.callback_charges_path}?access_token=#{@user.access_token}"
      end

      def activate_user(app_plan, charge = nil)
        charge&.activate
        @user.update(active_charge: true, charged_at: Time.current)
        @shop.update(app_plan: app_plan)
        @shop.current_time_period.update(monthly_usd: charge&.price || 0)

        send_charge_activated_analytics(charge&.price || 0)
      end

      def send_charge_activated_analytics(price)
        Analytics.identify(
          user_id: @user.id,
          traits: {
            monthlyUsd: price
          }
        )

        Analytics.track(
          user_id: @user.id,
          event: "Charge Activated",
          properties: {
            monthly_usd: price,
            email: @user.email
          }
        )
      end

      def api_shop
        @api_shop ||= ShopifyAPI::Shop.current
      end
    end
  end
end
