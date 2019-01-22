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
        maybe_reinstall_or_uninstall(uninstalled)
        maybe_reopen(plan_name)
        maybe_hand_off_or_cancel(plan_name)

        @shop.assign_attributes(plan_name: plan_name, uninstalled: uninstalled)
        @user.save! if @user.present?
        @shop.save!
      end

      def maybe_reinstall_or_uninstall(uninstall)
        if newly_reinstalled?(uninstall)
          track_reinstalled

          # TODO: convert to TimePeriod change
          # @shop.reinstalled_at = Time.current
          @user.charged_at = nil
        elsif newly_uninstalled?(uninstall)
          track_uninstalled

          @user&.active_charge = false
        end
      end

      def maybe_reopen(plan_name)
        return unless newly_reopened?(plan_name)

        track_reopened
        # TODO: convert to TimePeriod change
        # @shop.reopened_at = Time.current
        @user.charged_at = nil
      end

      def maybe_hand_off_or_cancel(plan_name)
        if handed_off?(plan_name)
          track_handed_off(plan_name)

          @user.active_charge = true
        elsif cancelled?(plan_name)
          track_cancelled
        end
      end

      def newly_reinstalled?(uninstalled)
        @shop.uninstalled? && !uninstalled
      end

      def newly_uninstalled?(uninstalled)
        !@shop.uninstalled? && uninstalled
      end

      # Cancelled -> something else
      def newly_reopened?(plan_name)
        @shop.cancelled? && plan_name != ::Shop::PLAN_CANCELLED
      end

      # Handoff means that the plan goes from "affiliate" to "frozen"
      def handed_off?(plan_name)
        @shop.affiliate? && plan_name == ::Shop::PLAN_FROZEN
      end

      # Shop was not previously cancelled but is now
      def cancelled?(plan_name)
        !@shop.cancelled? && plan_name == ::Shop::PLAN_CANCELLED
      end

      def track_reopened
        Analytics.track(
          user_id: @user.id,
          event: "Shop Reopened",
          properties: {
            "registration method": "shopify",
            email: @user.email
          }
        )
      end

      def track_reinstalled
        Analytics.track(
          user_id: @user.id,
          event: "App Reinstalled",
          properties: {
            "registration method": "shopify",
            email: @user.email,
            shopify_plan: @user.shop.plan_name
          }
        )
      end

      def track_uninstalled
        return if @user.blank?

        shop = @user.shop
        current_time_period = shop.current_time_period

        Analytics.track(
          user_id: @user.id,
          event: "App Uninstalled",
          properties: {
            activeCharge: @user.has_active_charge?,
            email: @user.email,
            shopify_plan: shop.plan_name,
            subscription_length: @user.subscription_length,
            current_days_installed: current_time_period.lapsed_days,
            total_days_installed: shop.total_days_installed,
            current_periods_paid: current_time_period.periods_paid,
            total_periods_paid: shop.total_periods_paid,
            current_monthly_usd: current_time_period.monthly_usd.to_f,
            total_usd_paid: shop.total_usd_paid.to_f
          }
        )
      end

      def track_handed_off(plan_name)
        Analytics.track(
          user_id: @user.id,
          event: "Shop Handed Off",
          properties: {
            plan_name: plan_name,
            email: @user.email
          }
        )
      end

      def track_cancelled
        shop = @user.shop
        current_time_period = shop.current_time_period

        Analytics.track(
          user_id: @user.id,
          event: "Shop Closed",
          properties: {
            email: @user.email,
            subscription_length: @user.subscription_length,
            current_days_installed: current_time_period.lapsed_days,
            total_days_installed: shop.total_days_installed,
            current_periods_paid: current_time_period.periods_paid,
            total_periods_paid: shop.total_periods_paid,
            current_monthly_usd: current_time_period.monthly_usd.to_f,
            total_usd_paid: shop.total_usd_paid.to_f
          }
        )
      end

      def track_installed
        Analytics.track(
          user_id: @user.id,
          event: "App Installed",
          properties: {
            "registration method": "shopify",
            email: @user.email,
            shopify_plan: @user.shop.plan_name
          }
        )
      end

      def reconcile_with_shopify
        success = true

        ShopifyAPI::Session.temp(@shop.shopify_domain, @shop.shopify_token) do
          begin
            shopify_shop = ShopifyAPI::Shop.current
            update_shop(plan_name: shopify_shop.plan_name, uninstalled: false)
          rescue ActiveResource::UnauthorizedAccess => e
            # we no longer have access to the shop- app uninstalled
            update_shop(plan_name: @shop.plan_name, uninstalled: true)
            success = false
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

        return success
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
