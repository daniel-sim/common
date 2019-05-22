module PR
  module Common
    module SkipShopifyAuthentication
      extend ActiveSupport::Concern

      included do
        skip_before_action :login_again_if_different_shop
        skip_around_action :shopify_session
      end
    end
  end
end
