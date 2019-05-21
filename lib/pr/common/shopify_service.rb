module PR
  module Common
    class ShopifyService
      def initialize(shop:)
        @shop = shop
        @user = @shop.user
      end

      def update_user(email:)
        @user.update(email: email)
      end

      def update_shop(options = {})
        # This method used to explicitly require "shopify_plan" and "uninstalled" only as params
        shopify_plan = options[:shopify_plan] = options.fetch(:shopify_plan, @shop.shopify_plan)
        uninstalled = options[:uninstalled] = options.fetch(:uninstalled, @shop.uninstalled)

        maybe_update_shopify_plan(shopify_plan)
        maybe_reinstall_or_uninstall(shopify_plan, uninstalled)
        maybe_reopen(shopify_plan)
        maybe_hand_off_or_cancel(shopify_plan)

        @shop.assign_attributes(options)
        @user&.save! # the check is legacy; some shops do not have a user, and we can't always create one.
        @shop.save!
      end

      def maybe_reinstall_or_uninstall(shopify_plan, uninstall)
        if newly_reinstalled?(uninstall)
          @shop.app_plan = nil
          @user.charged_at = nil

          track_reinstalled(shopify_plan)
        elsif newly_uninstalled?(uninstall)
          track_uninstalled

          @user.active_charge = false
        end
      end

      def maybe_reopen(shopify_plan)
        return unless newly_reopened?(shopify_plan)

        track_reopened(shopify_plan)
        @user.charged_at = Time.current
      end

      def maybe_update_shopify_plan(shopify_plan)
        return unless @shop.shopify_plan
        return unless shopify_plan_differs?(shopify_plan)

        track_shopify_plan_updated(shopify_plan)
      end

      def track_shopify_plan_updated(shopify_plan)
        Rails.logger.info "track_shopify_plan_updated for user #{@user.id}, shop #{@shop.id}"

        return if @user.blank?

        Analytics.identify(
          user_id: @user.id,
          traits: {
            email: @user.email,
            shopifyPlan: shopify_plan
          }
        )

        Analytics.track(
          user_id: @user.id,
          event: "Shopify Plan Updated",
          properties: {
            email: @user.email,
            pre_shopify_plan: @shop.shopify_plan,
            post_shopify_plan: shopify_plan
          }
        )
      end

      def maybe_hand_off_or_cancel(shopify_plan)
        if handed_off?(shopify_plan)
          track_handed_off(shopify_plan)
        elsif cancelled?(shopify_plan)
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
      def newly_reopened?(shopify_plan)
        @shop.cancelled? && shopify_plan != ::Shop::PLAN_CANCELLED
      end

      # Handoff means that the plan goes from "affiliate" to "frozen"
      def handed_off?(shopify_plan)
        @shop.affiliate? && shopify_plan == ::Shop::PLAN_FROZEN
      end

      # Shop was not previously cancelled but is now
      def cancelled?(shopify_plan)
        !@shop.cancelled? && shopify_plan == ::Shop::PLAN_CANCELLED
      end

      def track_cancelled
        Rails.logger.info "track_cancelled for user #{@user.id}, shop #{@shop.id}"

        return if @user.blank?

        shop = @user.shop
        current_time_period = shop.current_time_period

        Analytics.identify(
          user_id: @user.id,
          traits: {
            email: @user.email,
            status: :inactive,
            subscriptionLength: @user.subscription_length,
            currentDaysInstalled: current_time_period.lapsed_days,
            totalDaysInstalled: shop.total_days_installed,
            currentPeriodsPaid: current_time_period.periods_paid,
            totalPeriodsPaid: shop.total_periods_paid,
            monthlyUsd: current_time_period.monthly_usd.to_f,
            currentUsdPaid: current_time_period.usd_paid.to_f,
            totalUsdPaid: shop.total_usd_paid.to_f
          }
        )

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
            monthly_usd: current_time_period.monthly_usd.to_f,
            current_usd_paid: current_time_period.usd_paid.to_f,
            total_usd_paid: shop.total_usd_paid.to_f
          }
        )
      end

      def track_installed
        Rails.logger.info "track_installed for user #{@user.id}, shop #{@shop.id}"

        return if @user.blank?

        Analytics.identify(
          user_id: @user.id,
          traits: {
            email: @user.email,
            status: :active,
            shopifyPlan: @shop.shopify_plan,
            appPlan: @shop.app_plan,
            promo_code: @shop.promo_code&.code
          }
        )

        Analytics.track(
          user_id: @user.id,
          event: "App Installed",
          properties: {
            "registration method": "shopify",
            email: @user.email,
            shopify_plan: @user.shop.shopify_plan,
            promo_code: @shop.promo_code&.code
          }
        )
      end

      # Set the `pricing_method` in PR::Common::Configuration.
      # If it's a symbol, it will be called on this service.
      # If it's callable (e.g. a lambda) then it'll be called with @shop and the args.
      # If not configured (by default) it will call `:determine_price_by_plan_name`.
      def determine_price(args = {})
        pricing_method = PR::Common.config.pricing_method

        price = if pricing_method.is_a?(Symbol)
                  send(pricing_method, args)
                elsif pricing_method.respond_to?(:call)
                  pricing_method.call(@shop, args)
                else
                  raise "Pricing method is not valid."
                end

        maybe_apply_promo_code_to_price(price)
      end

      def maybe_apply_promo_code_to_price(price)
        return price if @shop.promo_code.blank?

        # promo code is a "percentage" of the total. By default it's 100.0.
        # 200.0 = double price
        # 50.0 = half price
        # 0.0 = free
        price.merge(price: ((@shop.promo_code.value / 100) * price[:price]).ceil(2))
      end

      def reconcile_with_shopify
        success = true

        ShopifyAPI::Session.temp(@shop.shopify_domain, @shop.shopify_token) do
          begin
            shopify_shop = ShopifyAPI::Shop.current
            ensure_user_exists(shopify_shop.email)
            update_shop(shopify_plan: shopify_shop.plan_name, uninstalled: false)
          rescue ActiveResource::UnauthorizedAccess => e
            # we no longer have access to the shop- app uninstalled
            update_shop(shopify_plan: @shop.shopify_plan, uninstalled: true)
            success = false
          rescue ActiveResource::ClientError => e
            case e.response.code.to_s
            when "401" then update_shop(shopify_plan: @shop.shopify_plan, uninstalled: true)
            when "402" then update_shop(shopify_plan: Shop::PLAN_FROZEN, uninstalled: false)
            when "403" then update_shop(shopify_plan: Shop::PLAN_FRAUDULENT, uninstalled: false)
            when "404" then update_shop(shopify_plan: Shop::PLAN_CANCELLED, uninstalled: false)
            when "423" then update_shop(shopify_plan: Shop::PLAN_LOCKED, uninstalled: false)
            end
          end
          ShopifyAPI::Base.clear_session
        end

        return success
      end

      def remote_shop
        begin
          ShopifyAPI::Shop.current
        rescue StandardError => exception
          raise ShopifyErrors.convert(exception, @shop.shopify_domain)
        end
      end

      def track_handed_off(shopify_plan)
        Rails.logger.info "track_handed_off for user #{@user.id}, shop #{@shop.id}"

        return if @user.blank?

        Analytics.identify(
          user_id: @user.id,
          traits: {
            email: @user.email,
            shopifyPlan: shopify_plan
          }
        )

        Analytics.track(
          user_id: @user.id,
          event: "Shop Handed Off",
          properties: {
            shopify_plan: shopify_plan,
            email: @user.email
          }
        )
      end

      private

      # This is here to deal with edge cases in which a user was never created
      def ensure_user_exists(email)
        @user ||= PR::Common::UserService.new.find_or_create_user_by_shopify(email: email, shop: @shop)
        @shop.reload
      end

      def determine_price_by_plan_name(args = {})
        plan = args[:api_shop] ? args[:api_shop].plan_name : @shop.shopify_plan

        # List prices in ascending order in config
        pricing = PR::Common.config.pricing

        best_price = pricing.last

        pricing.each do |price|
          best_price = price if price[:shopify_plan] == plan
        end

        best_price
      end

      def track_reopened(shopify_plan)
        Rails.logger.info "track_reopened for user #{@user.id}, shop #{@shop.id}"

        return if @user.blank?

        Analytics.identify(
          user_id: @user.id,
          traits: {
            email: @user.email,
            status: :active,
            shopifyPlan: shopify_plan,
            promo_code: @shop.promo_code&.code
          }
        )

        Analytics.track(
          user_id: @user.id,
          event: "Shop Reopened",
          properties: {
            "registration method": "shopify",
            email: @user.email,
            shopify_plan: shopify_plan,
            promo_code: @shop.promo_code&.code
          }
        )
      end

      def track_reinstalled(shopify_plan)
        Rails.logger.info "track_reinstalled for user #{@user.id}, shop #{@shop.id}"

        return if @user.blank?

        Analytics.identify(
          user_id: @user.id,
          traits: {
            email: @user.email,
            status: :active,
            shopifyPlan: shopify_plan,
            appPlan: @shop.app_plan,
            monthlyUsd: 0, # always reset to 0 on reinstall
            activeCharge: @user.active_charge,
            trial: false,
            promo_code: @shop.promo_code&.code
          }
        )

        Analytics.track(
          user_id: @user.id,
          event: "App Reinstalled",
          properties: {
            "registration method": "shopify",
            email: @user.email,
            shopify_plan: shopify_plan,
            promo_code: @shop.promo_code&.code
          }
        )
      end

      def track_uninstalled
        Rails.logger.info "track_uninstalled for user #{@user.id}, shop #{@shop.id}"

        return if @user.blank?

        shop = @user.shop
        current_time_period = shop.current_time_period

        Analytics.identify(
          user_id: @user.id,
          traits: {
            email: @user.email,
            status: :uninstalled,
            subscriptionLength: @user.subscription_length,
            currentDaysInstalled: current_time_period.lapsed_days,
            totalDaysInstalled: shop.total_days_installed,
            currentPeriodsPaid: current_time_period.periods_paid,
            totalPeriodsPaid: shop.total_periods_paid,
            monthlyUsd: current_time_period.monthly_usd.to_f,
            currentUsdPaid: current_time_period.usd_paid.to_f,
            totalUsdPaid: shop.total_usd_paid.to_f
          }
        )

        Analytics.track(
          user_id: @user.id,
          event: "App Uninstalled",
          properties: {
            email: @user.email,
            subscription_length: @user.subscription_length,
            current_days_installed: current_time_period.lapsed_days,
            total_days_installed: shop.total_days_installed,
            current_periods_paid: current_time_period.periods_paid,
            total_periods_paid: shop.total_periods_paid,
            monthly_usd: current_time_period.monthly_usd.to_f,
            current_usd_paid: current_time_period.usd_paid.to_f,
            total_usd_paid: shop.total_usd_paid.to_f
          }
        )
      end

      def shopify_plan_differs?(shopify_plan)
        shopify_plan.to_s != @shop.shopify_plan.to_s
      end
    end
  end
end
