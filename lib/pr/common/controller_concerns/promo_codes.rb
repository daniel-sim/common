module PR
  module Common
    module PromoCodes
      extend ActiveSupport

      def maybe_reconcile_promo_codes(shop)
        maybe_remove_existing_promo_code(shop)
        maybe_apply_promo_code(shop)
      end

      private

      # We only want to remove promo codes for shops that are reinstalling
      def maybe_remove_existing_promo_code(shop)
        return if shop.installed?

        shop.update!(promo_code: nil)
      end

      def maybe_apply_promo_code(shop)
        session_service = SessionPromoCodeService.new(session)
        session_service.maybe_apply_to_shop(shop)
        session_service.clear
      end

      def maybe_store_promo_code
        SessionPromoCodeService.new(session).clear

        params_service = ParamsPromoCodeService.new(params)

        return unless params_service.present?

        if params_service.error
          flash[:error] = params_service.error
          render :new, promo_code: params_service.code, shop: params[:shop]
          return
        end

        SessionPromoCodeService.new(session).store(params_service.record)
      end
    end
  end
end
