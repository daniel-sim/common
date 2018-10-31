require 'shopify_app/shop'
require 'shopify_app/session_storage'
module PR
  module Common
    module Models
      module Shop
        extend ActiveSupport::Concern

        include ::ShopifyApp::Shop
        include ::ShopifyApp::SessionStorage
        include ::PR::Common::Redactable

        included do
          redactable :shopify_domain, :string, unique: true
          after_redaction :redact_user

          # The 'tree' symbol plan name is a reference to the deprecated '420' Shopify response code
          # it shouldn't happen anymore but we decided to leave it just for fun
          # In 2018 420 code was changed to 423 and corresponding to the 'locked' status
          # https://ecommerce.shopify.com/c/api-announcements/t/upcoming-change-to-api-response-status-code-for-locked-stores-536419
          scope :with_active_plan, -> { where.not(plan_name: %w[cancelled frozen 🌲 locked]) }
          scope :with_active_charge, -> { joins(:user).where(users: { active_charge: true }) }
          scope :installed, -> { where(uninstalled: false) }
        end

        class_methods do
          # add class methods here
        end

        def redact_user
          return unless respond_to?(:user)

          user&.redact!
        end
      end
    end
  end
end
