module PR
  module Common
    class AffiliateRedirect
      def initialize(app)
        @app = app
      end

      def call(env)
        status, headers, body = @app.call(env)
        @request = Rack::Request.new(env)

        return handle_referral if referrer?

        [status, headers, body]
      end

      private

      def referrer?
        @request.env['rack.request.query_hash']['ref'] && PR::Common.config.referrer_redirect
      end

      def handle_referral
        handle_promo_code

        [
          302,
          {'Location' => PR::Common.config.referrer_redirect, 'Content-Type' => 'text/html'},
          ['Found']
        ]
      end

      def handle_promo_code
        service = SessionPromoCodeService.new(@request.session)

        service.clear

        return if (code = @request.params["promo_code"]).blank?

        promo_code = PR::Common::Models::PromoCode.find_by(code: code)

        return if promo_code.blank?

        service.store(promo_code)
      end
    end
  end
end
