require "rails_helper"

describe PR::Common::SustainedAnalyticsService do
  subject(:service) { described_class.new(shop) }

  let!(:shop) { create(:shop, :with_user, shopify_plan: "basic", charged_at: current_time) }
  let(:current_time_period) { shop.current_time_period }
  let(:current_time) { Time.zone.local(2018, 1, 14, 0, 0, 1) }

  before do
    current_time_period.update!(monthly_usd: 10) # this should be set from activating the charge
  end

  around { |example| Timecop.freeze(current_time, &example.method(:run)) }

  describe "#perform" do
    describe "payment charged" do
      context "when shop was converted to paid 30 days ago" do
        let(:current_time) { Time.zone.local(2018, 1, 31, 0, 0, 1) }

        before do
          current_time_period.update!(converted_to_paid_at: Time.zone.local(2018, 1, 1))
        end

        it "updates period_last_paid_at to now" do
          expect { service.perform }
            .to change { current_time_period.reload.period_last_paid_at }
            .from(nil)
            .to(current_time)
        end

        it "increments periods_paid" do
          expect { service.perform }
            .to change { current_time_period.reload.periods_paid }
            .from(0)
            .to(1)
        end

        it "sends an identify analytic" do
          expect(Analytics).to receive(:identify)
            .with(
              user_id: shop.user.id,
              traits: {
                currentPeriodsPaid: 1,
                totalPeriodsPaid: 1,
                monthlyUsd: 10.0,
                currentUsdPaid: 10.0,
                totalUsdPaid: 10.0
              }
            )

          service.perform
        end

        it "sends a Payment Charged track analytic" do
          expect(Analytics).to receive(:track)
            .with(
              user_id: shop.user.id,
              event: "Payment Charged",
              properties: {
                email: shop.user.email,
                current_periods_paid: 1,
                total_periods_paid: 1,
                monthly_usd: 10.0,
                current_usd_paid: 10.0,
                total_usd_paid: 10.0
              }
            )

          service.perform
        end
      end
    end

    context "when shop's current time period is installed" do
      context "when time period started under 7 days ago and shop_retained_analytic_sent_at is nil" do
        before { current_time_period.update!(start_time: current_time) }

        it "does not send an identify analytic" do
          expect(Analytics).not_to receive(:identify)

          service.perform
        end

        it "does not send a track analytic" do
          expect(Analytics).not_to receive(:track)

          service.perform
        end

        it "does not change the time period's shop_retained_analytic_sent_at" do
          expect { service.perform }
            .not_to change(current_time_period, :shop_retained_analytic_sent_at)
            .from(nil)
        end
      end

      context "when time period was started over 7 days ago and shop_retained_analytic_sent_at is nil" do
        before do
          current_time_period.update!(start_time: Time.zone.local(2018, 1, 7))
          shop.update!(charged_at: Time.zone.local(2018, 1, 7), app_plan: :generic)
        end

        it "sends identify analytics" do
          expect(Analytics).to receive(:identify)
            .with(
              user_id: shop.user.id,
              traits: {
                trial: false,
               monthlyUsd: 10.0,
                appPlan: "generic"
              }
            )

          expect(Analytics).to receive(:identify)
            .with(
              user_id: shop.user.id,
              traits: {
                monthlyUsd: 10.0,
                currentPeriodsPaid: 1,
                currentUsdPaid: 10.0,
                totalPeriodsPaid: 1,
                totalUsdPaid: 10.0
              }
            )

          expect(Analytics).to receive(:identify)
            .with(
              user_id: shop.user.id,
              traits: {
                currentDaysInstalled: 8,
                totalDaysInstalled: 8
              }
            )

          service.perform
        end

        it "sends track analytics" do
          expect(Analytics).to receive(:track)
            .with(
              user_id: shop.user.id,
              event: "Converted to Paid",
              properties: {
                email: shop.user.email,
                monthly_usd: 10.0,
                app_plan: "generic"
              }
            )

          expect(Analytics).to receive(:track)
            .with(
              user_id: shop.user.id,
              event: "Payment Charged",
              properties: {
                email: shop.user.email,
                monthly_usd: 10.0,
                current_periods_paid: 1,
                current_usd_paid: 10.0,
                total_periods_paid: 1,
                total_usd_paid: 10.0
              }
            )


          expect(Analytics).to receive(:track)
            .with(
              user_id: shop.user.id,
              event: "Shop Retained",
              properties: {
                email: shop.user.email,
                current_days_installed: 8,
                total_days_installed: 8
              }
            )

          service.perform
        end

        it "updates the time period's shop_retained_analytic_sent_at to the current time" do
          expect { service.perform }
            .to change { current_time_period.reload.shop_retained_analytic_sent_at }
            .from(nil)
            .to(current_time)
        end
      end

      context "when time period was started over 7 days ago and shop_retained_analytic_sent_at was under 7 days ago" do
        before do
          current_time_period.update!(start_time: Time.zone.local(2018, 1, 1),
                                      shop_retained_analytic_sent_at: current_time)
        end

        it "does not send an identify analytic" do
          expect(Analytics).not_to receive(:identify)

          service.perform
        end

        it "does not send a track analytic" do
          expect(Analytics).not_to receive(:track)

          service.perform
        end

        it "does not change the time period's shop_retained_analytic_sent_at" do
          expect { service.perform }
            .not_to change { current_time_period.reload.shop_retained_analytic_sent_at }
        end
      end

      context "when time period was started over 7 days ago and shop_retained_analytic_sent_at is over 7 days ago" do
        before do
          current_time_period.update!(start_time: Time.zone.local(2018, 1, 1),
                                      shop_retained_analytic_sent_at: Time.zone.local(2018, 1, 7))
        end

        it "sends an identify analytic" do
          expect(Analytics).to receive(:identify)
            .with(
              user_id: shop.user.id,
              traits: {
                currentDaysInstalled: 14,
                totalDaysInstalled: 14
              }
            )

          service.perform
        end

        it "sends a track analytic" do
          expect(Analytics).to receive(:track)
            .with(
              user_id: shop.user.id,
              event: "Shop Retained",
              properties: {
                email: shop.user.email,
                current_days_installed: 14,
                total_days_installed: 14
              }
            )

          service.perform
        end

        it "updates the time period's shop_retained_analytic_sent_at to the current time" do
          expect { service.perform }
            .to change { current_time_period.reload.shop_retained_analytic_sent_at }
            .to(current_time)
        end
      end
    end
  end
end
