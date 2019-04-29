require "shopify_app"

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

        include ::ShopifyApp::SessionStorage

        included do
          delegate :charged_at, to: :user
          delegate :charged_at=, to: :user
          scope :with_active_plan, -> { where.not(shopify_plan: INACTIVE_PLANS) }
          scope :with_active_charge, -> { joins(:user).where(users: { active_charge: true }) }
          scope :installed, -> { where(uninstalled: false) }

          has_one :user
          has_many :time_periods, dependent: :destroy, class_name: "PR::Common::Models::TimePeriod"
          before_validation :reconcile_time_periods

          # TODO:
          # This ensures that every pre-existing shop has a time period before it is
          # operated on.
          # This should be removed once all existing shops in all apps already have a time period.
          after_find -> { reconcile_time_periods && save }, if: -> { time_periods.blank? }
        end

        def api_session
          ShopifyAPI::Session.new(
            domain: shopify_domain,
            token: shopify_token,
            api_version: api_version
          )
        end

        def activate_session
          ShopifyAPI::Base.activate_session(api_session)
        end

        def api_version
          ShopifyApp.configuration.api_version
        end

        def status
          return :uninstalled if uninstalled

          case shopify_plan
          when PLAN_FROZEN, PLAN_CANCELLED, PLAN_FRAUDULENT then return :inactive
          when PLAN_LOCKED then return :locked
          end

          :active
        end

        def inactive?
          !active?
        end

        def active?
          active_shopify_plan? && user&.active_charge && !uninstalled
        end

        def active_shopify_plan?
          shopify_plan && !inactive_shopify_plan?
        end

        def inactive_shopify_plan?
          INACTIVE_PLANS.include? shopify_plan
        end

        def frozen?
          shopify_plan == PLAN_FROZEN
        end

        def cancelled?
          shopify_plan == PLAN_CANCELLED
        end

        alias closed? cancelled?

        def affiliate?
          shopify_plan == PLAN_AFFILIATE
        end

        def current_time_period
          time_periods.not_yet_ended.order(:start_time).last
        end

        def total_days_installed
          time_periods.whilst_in_use.sum(&:lapsed_days)
        end

        def total_periods_paid
          time_periods.sum(:periods_paid)
        end

        def total_usd_paid
          time_periods.sum(&:usd_paid)
        end

        def app_plan
          super || PR::Common.config.default_app_plan
        end

        private

        def reconcile_time_periods
          maybe_build_uninstalled_time_period && return
          maybe_build_closed_time_period && return
          maybe_build_reinstalled_time_period && return
          maybe_build_reopened_time_period && return
          maybe_build_installed_time_period
        end

        def maybe_build_uninstalled_time_period
          return unless uninstalled?
          return true if current_time_period&.uninstalled? # current time period is already uninstalled

          reconcile_time_period(:uninstalled)

          true
        end

        def maybe_build_closed_time_period
          return unless closed?
          return true if current_time_period&.closed? # current time period is already closed

          reconcile_time_period(:closed)

          true
        end

        # When not uninstalled but current time period is uninstalled
        def maybe_build_reinstalled_time_period
          return if uninstalled?
          return unless current_time_period&.uninstalled?

          reconcile_time_period(:reinstalled)
          true
        end

        # When not closed but current time period is closed
        def maybe_build_reopened_time_period
          return if closed?
          return unless current_time_period&.closed?

          reconcile_time_period(:reopened)

          true
        end

        def maybe_build_installed_time_period
          return if current_time_period

          build_new_time_period(:installed)
          true
        end

        def reconcile_time_period(kind)
          current_time = DateTime.current

          current_time_period.update!(end_time: current_time) if current_time_period.present?

          build_new_time_period(kind, start_time: current_time)
        end

        def build_new_time_period(kind, start_time: DateTime.current)
          time_periods.reload

          new_params = {
            start_time: start_time,
            kind: kind
          }

          if (time_period = time_periods.last).present? && kind != :reinstalled
            new_params.merge!(
              converted_to_paid_at: time_period.converted_to_paid_at,
              monthly_usd: time_period.monthly_usd,
              period_last_paid_at: time_period.period_last_paid_at
            )
          end

          time_periods.build(new_params)
        end
      end
    end
  end
end
