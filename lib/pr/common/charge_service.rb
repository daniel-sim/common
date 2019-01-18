module PR
  module Common
    class ChargeService
      def initialize(shop)
        @shop = shop
        @user = shop.user
      end

      def create_charge(price, base_url)
        ShopifyAPI::RecurringApplicationCharge.current&.cancel

        price.positive? ? create_nonfree_charge(price, base_url) : create_free_charge
      end

      def activate_charge(charge)
        charge.activate
        @user.update(active_charge: true, charged_at: Time.current)

        send_charge_activated_analytic(charge.price)
      end

      private

      def create_free_charge
        @user.update(active_charge: true, charged_at: Time.current)
        send_charge_activated_analytic(0)
      end

      def create_nonfree_charge(price, base_url)
        ShopifyAPI::RecurringApplicationCharge
          .create(charge_params(base_url))
      end

      def charge_params(base_url)
        PR::Common::ShopifyService
          .new(shop: @shop)
          .determine_price(plan_name: api_shop.plan_name)
          .merge(test: !Rails.env.production?,
                 return_url: return_url(base_url))
          .except(:key)
      end

      def return_url(base_url)
        "#{base_url}#{Rails.application.routes.url_helpers.callback_charges_path}?access_token=#{@user.access_token}"
      end

      def activate_user(charge = nil)
        charge.activate
        @user.update(active_charge: true, charged_at: Time.current)

        send_charge_activated_analytic(@shop.user, charge)
      end

      def send_charge_activated_analytic(price)
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
