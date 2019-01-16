require "shopify_app/shop"
require "shopify_app/session_storage"
module PR
  module Common
    module Models
      module Shop
        PLAN_FROZEN = "frozen".freeze
        PLAN_CANCELLED = "cancelled".freeze
        PLAN_LOCKED = "locked".freeze
        PLAN_AFFILIATE = "affiliate".freeze

        INACTIVE_PLANS = [PLAN_CANCELLED, PLAN_FROZEN, PLAN_LOCKED, "🌲"].freeze

        extend ActiveSupport::Concern

        include ::ShopifyApp::Shop
        include ::ShopifyApp::SessionStorage

        included do
          delegate :charged_at, to: :user
          delegate :charged_at=, to: :user
          # The 'tree' symbol plan name is a reference to the deprecated '420' Shopify response code
          # it shouldn't happen anymore but we decided to leave it just for fun
          # In 2018 420 code was changed to 423 and corresponding to the 'locked' status
          # https://ecommerce.shopify.com/c/api-announcements/t/upcoming-change-to-api-response-status-code-for-locked-stores-536419
          scope :with_active_plan, -> { where.not(plan_name: INACTIVE_PLANS) }
          scope :with_active_charge, -> { joins(:user).where(users: { active_charge: true }) }
          scope :installed, -> { where(uninstalled: false) }

          has_one :user
          has_many :time_periods, dependent: :destroy
        end

        def frozen?
          plan_name == PLAN_FROZEN
        end

        def cancelled?
          plan_name == PLAN_CANCELLED
        end

        def affiliate?
          plan_name == PLAN_AFFILIATE
        end
      end
    end
  end
end
