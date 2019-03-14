module PR
  module Common
    class Configuration
      attr_accessor :signup_params, :send_welcome_email,
                    :send_confirmation_email, :referrer_redirect,
                    :pricing, :default_app_plan

      attr_writer :pricing_method

      # Symbol of method to call on ShopifyService or lambda.
      def pricing_method
        @pricing_method || :determine_price_by_plan_name
      end
    end
  end
end
