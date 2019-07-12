require "pr/common/version"
require "pr/common/engine"
require "pr/common/configuration"
require "pr/common/tokenable"
require "pr/common/token_authenticable"
require "pr/common/affiliate_redirect"
require "pr/common/models/application_record"
require "pr/common/models/user"
require "pr/common/models/shop"
require "pr/common/models/time_period"
require "pr/common/models/promo_code"
require "pr/common/models/admin"
require "pr/common/user_service"
require "pr/common/shopify_service"
require "pr/common/webhook_service"
require "pr/common/sustained_analytics_service"
require "pr/common/params_promo_code_service"
require "pr/common/session_promo_code_service"
require "pr/common/charge_service"
require "pr/common/sign_in_service"
require "pr/common/controller_concerns/promo_codes"
require "pr/common/controller_concerns/skip_shopify_authentication"
require "pr/common/controllers/sessions_controller"
require "pr/common/controllers/webhooks_controller"
require "pr/common/controllers/callback_controller"
require "exceptions/shopify"
require "exceptions/ignored_wrapper"

module PR
  module Common
    def self.configure
      yield config
    end

    def self.config
      @config ||= Configuration.new
    end

    def self.config=(config)
      @config = config
    end

    def self.client_url
      Settings.client_url
    end

    def self.api_url
      Settings.api_url
    end
  end
end
