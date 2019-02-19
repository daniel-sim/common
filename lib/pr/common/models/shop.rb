require 'shopify_app/shop'
require 'shopify_app/session_storage'
module PR
  module Common
    module Models
      module Shop
        PLAN_FROZEN = "frozen".freeze
        PLAN_CANCELLED = "cancelled".freeze
        PLAN_LOCKED = "locked".freeze
        PLAN_AFFILIATE = "affiliate".freeze
        PLAN_FRAUDULENT = "fraudulent".freeze

        INACTIVE_PLANS = [PLAN_CANCELLED, PLAN_FROZEN, PLAN_LOCKED, PLAN_FRAUDULENT].freeze

        extend ActiveSupport::Concern

        include ::ShopifyApp::Shop
        include ::ShopifyApp::SessionStorage

        included do
          delegate :charged_at, to: :user
          delegate :charged_at=, to: :user
          scope :with_active_plan, -> { where.not(plan_name: INACTIVE_PLANS) }
          scope :with_active_charge, -> { joins(:user).where(users: { active_charge: true }) }
          scope :installed, -> { where(uninstalled: false) }

          before_update :reinstalled!, if: :just_reinstalled?
        end

        def reinstalled!
          self.uninstalled = false
          self.reinstalled_at = Time.current
        end

        private

        def just_reinstalled?
          uninstalled_changed? && !uninstalled
        end
      end
    end
  end
end
