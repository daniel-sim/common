module PR
  module Common
    class Configuration
      attr_accessor :signup_params, :send_welcome_email,
                    :send_confirmation_email, :referrer_redirect,
                    :pricing, :default_app_plan
    end
  end
end
