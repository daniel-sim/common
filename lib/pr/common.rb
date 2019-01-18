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
require "pr/common/user_service"
require "pr/common/shopify_service"
require "pr/common/webhook_service"
require "pr/common/sustained_analytics_service"

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
  end
end
