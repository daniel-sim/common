namespace 'common' do
  namespace 'webhooks' do
    desc "Recreate all webhooks based on config. Optionally pass a comma-separated list of domains."
    task :recreate, [:shops_file] => [:environment] do |_, args|
      FileUtils.mkdir_p(Rails.root.join('tmp'))
      Rails.logger = Logger.new Rails.root.join('tmp', 'common-webhooks-recreate.log')

      shops = if args[:shops_file].present?
                Shop.where( shopify_domain: File
                                            .read(args[:shops_file])
                                            .split('\s')
                                            .map(&:strip))
              else
                Shop.installed
              end

      puts PR::Common::WebhookService.recreate_webhooks!(shops)
    end
  end

  namespace "shops" do
    desc "Reconcile shops"
    task reconcile: :environment do
      PR::Common::ShopUpdateReconcileJob.enqueue
    end
  end

  namespace "import" do
    # This is a one-off task to import payment history, populating the last payment
    # and sending relevant analytics. It's not well tested, and is intended to be removed
    # when it has been run across all apps.
    #
    # Notes:
    # There may be duplicate shops (we will use only the one with the most recent end date)
    # Every row must have an `end_date`
    # If the end date is more than 100 days ago, we will ignore it
    # Each shop will be reconciled before any changes are made
    # Analytic will only be sent for shops whose time period is in TIME_PERIOD::KINDS_IN_USE, and
    # where the end period is <= current time
    desc "Payment history"
    task :payment_history, [:csv_file] => :environment do |_, args|
      shops = Hash.new { |h, k| h[k] = [] }

      CSV.foreach(Rails.root.join(args[:csv_file]), col_sep: ";", headers: :first_row) do |row|
        next if row["Billing Period End"].blank?
        shop_domain = row["Shop Domain"]
        period_end = Time.zone.parse(row["Billing Period End"])
        shops[shop_domain] << period_end
      end

      shops.each do |domain, period_end_dates|
        now = Time.current

        most_recent_date = period_end_dates.max

        if most_recent_date < (now - 100.days)
          puts "[#{domain}]: Most recent date is too old!\n\n"
          next
        end

        shop = Shop.find_by(shopify_domain: domain)
        unless shop
          puts "[#{domain}]: Could not find shop!\n\n"
          next
        end

        puts "[#{domain}]: Reconciling"
        reconciled = begin
                       PR::Common::ShopifyService.new(shop: shop).reconcile_with_shopify
                     rescue
                       puts "[#{domain}]: Reconciliation raised error!\n\n"
                       next
                     end

        unless reconciled
          puts "[#{domain}] Reconciliation failed!\n\n"
          next
        end

        current_time_period = shop.current_time_period

        if current_time_period.reload.closed? || current_time_period.uninstalled?
          puts "[#{domain}] Time period is #{current_time_period.kind}, so skipping.\n\n"
          next
        end

        current_time_period.update(period_last_paid_at: most_recent_date,
                                   periods_paid: current_time_period.periods_paid.next)
        puts "[#{domain}]: Setting last payment date: #{most_recent_date}, incrementing periods paid"

        if most_recent_date > now
          puts "[#{domain}]: Paid in the future; not sending analytics\n\n"
        else
          puts "[#{domain}]: Sending analytics\n\n"

          shop.reload

          current_periods_paid = current_time_period.periods_paid
          total_periods_paid = shop.total_periods_paid
          monthly_usd = current_time_period.monthly_usd.to_f
          current_usd_paid = current_time_period.usd_paid.to_f
          total_usd_paid = shop.total_usd_paid.to_f

          Analytics.identify(
            user_id: shop.user.id,
            traits: {
              currentPeriodsPaid: current_periods_paid,
              totalPeriodsPaid: total_periods_paid,
              monthlyUsd: monthly_usd,
              currentUsdPaid: current_usd_paid,
              totalUsdPaid: total_usd_paid
            }
          )

          Analytics.track(
            user_id: shop.user.id,
            event: "Payment Charged",
            properties: {
              email: shop.user.email,
              current_periods_paid: current_periods_paid,
              total_periods_paid: total_periods_paid,
              monthly_usd: monthly_usd,
              current_usd_paid: current_usd_paid,
              total_usd_paid: total_usd_paid
            }
          )

          Analytics.flush
        end
      end
    end
  end
end
