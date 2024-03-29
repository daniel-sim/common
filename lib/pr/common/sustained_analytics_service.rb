class PR::Common::SustainedAnalyticsService
  DAYS_BETWEEN_SHOP_RETAINED_ANALYTIC = Rails.env.staging? ? 1 : 7
  DAYS_UNTIL_PAYMENT_CHARGED = Rails.env.staging? ? 1 : 30

  # Strictly speaking, this should depend on the trial_days of various
  # prices. Potentially to be implemented in the future.
  DAYS_UNTIL_CONVERTED_TO_PAID = Rails.env.staging? ? 1 : 7

  # We allow passing in a current_time so that any comparisons / updates are done
  # with that time in mind. When run on a schedule, this job may differ slightly from day to day
  # so passing a normalized current time helps.
  def initialize(shop, options = {})
    @shop = shop
    @current_time_period = shop.current_time_period
    @user = shop.user
    @current_time = options.fetch(:current_time, Time.current)
  end

  def perform
    return unless @current_time_period
    return unless @current_time_period.in_use?
    return if @current_time_period.ended?

    maybe_converted_to_paid
    maybe_shop_retained
    maybe_payment_charged
  end

  private

  def maybe_shop_retained
    return if DAYS_BETWEEN_SHOP_RETAINED_ANALYTIC >
              @current_time_period.lapsed_days_since_last_shop_retained_analytic(@current_time)

    send_shop_retained_analytics

    @current_time_period.update!(shop_retained_analytic_sent_at: @current_time)
  end

  def send_shop_retained_analytics
    return if @user.blank?

    current_days_installed = @current_time_period.lapsed_days
    total_days_installed = @shop.total_days_installed

    Analytics.identify(
      user_id: @user.id,
      traits: {
        email: @user.email,
        currentDaysInstalled: current_days_installed,
        totalDaysInstalled: total_days_installed
      }
    )

    Analytics.track(
      user_id: @user.id,
      event: "Shop Retained",
      properties: {
        email: @user.email,
        current_days_installed: current_days_installed,
        total_days_installed: total_days_installed
      }
    )
  end

  def maybe_converted_to_paid
    return if @current_time_period.converted_to_paid?
    return if @current_time_period.monthly_usd.zero?
    return unless @shop.charged_at

    return if (@shop.charged_at + DAYS_UNTIL_CONVERTED_TO_PAID.days) > @current_time

    convert_to_paid && payment_charged
  end

  def convert_to_paid
    send_converted_to_paid_analytics

    @current_time_period.update!(converted_to_paid_at: @current_time)
  end

  def send_converted_to_paid_analytics
    return if @user.blank?

    Analytics.identify(
      user_id: @user.id,
      traits: {
        email: @user.email,
        trial: false,
        monthlyUsd: @current_time_period.monthly_usd,
        appPlan: @shop.app_plan
      }
    )

    Analytics.track(
      user_id: @user.id,
      event: "Converted to Paid",
      properties: {
        email: @user.email,
        monthly_usd: @current_time_period.monthly_usd,
        app_plan: @shop.app_plan
      }
    )
  end

  def maybe_payment_charged
    return unless @current_time_period.converted_to_paid?

    last_payment_charged = @current_time_period.period_last_paid_at ||
                           @current_time_period.converted_to_paid_at

    return if (last_payment_charged + DAYS_UNTIL_PAYMENT_CHARGED.days) > @current_time

    payment_charged
  end

  def payment_charged
    @current_time_period.paid_now!(@current_time)
    @shop.reload

    send_payment_charged_analytics
  end

  def send_payment_charged_analytics
    return if @user.blank?

    current_periods_paid = @current_time_period.periods_paid
    total_periods_paid = @shop.total_periods_paid
    monthly_usd = @current_time_period.monthly_usd.to_f
    current_usd_paid = @current_time_period.usd_paid.to_f
    total_usd_paid = @shop.total_usd_paid.to_f

    Analytics.identify(
      user_id: @user.id,
      traits: {
        email: @user.email,
        currentPeriodsPaid: current_periods_paid,
        totalPeriodsPaid: total_periods_paid,
        monthlyUsd: monthly_usd,
        currentUsdPaid: current_usd_paid,
        totalUsdPaid: total_usd_paid
      }
    )

    Analytics.track(
      user_id: @user.id,
      event: "Payment Charged",
      properties: {
        email: @user.email,
        current_periods_paid: current_periods_paid,
        total_periods_paid: total_periods_paid,
        monthly_usd: monthly_usd,
        current_usd_paid: current_usd_paid,
        total_usd_paid: total_usd_paid
      }
    )
  end
end
