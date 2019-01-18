class PR::Common::SustainedAnalyticsService
  DAYS_BETWEEN_SHOP_RETAINED_ANALYTIC = Rails.env.staging? ? 1 : 7

  # TODO: optimise queries
  def self.perform
    shops = Shop
            .joins(:time_periods)
            .merge(PR::Common::Models::TimePeriod.whilst_in_use.not_yet_ended)

    shops.find_each(&method(:maybe_shop_retained))
  end

  private_class_method def self.maybe_shop_retained(shop)
    current_time_period = shop.current_time_period || return

    return if DAYS_BETWEEN_SHOP_RETAINED_ANALYTIC > current_time_period.lapsed_days_since_last_shop_retained_analytic

    send_shop_retained_analytics(shop, current_time_period)

    current_time_period.update!(shop_retained_analytic_sent_at: Time.current)
  end

  private_class_method def self.send_shop_retained_analytics(shop, current_time_period)
    user = shop.user
    user_id = user.id
    current_days_installed = current_time_period.lapsed_days
    total_days_installed = shop.total_days_installed

    Analytics.identify(
      user_id: user_id,
      traits: {
        currentDaysInstalled: current_days_installed,
        totalDaysInstalled: total_days_installed
      }
    )

    Analytics.track(
      user_id: user_id,
      event: "Shop Retained",
      properties: {
        email: user.email,
        current_days_installed: current_days_installed,
        total_days_installed: total_days_installed
      }
    )
  end
end
