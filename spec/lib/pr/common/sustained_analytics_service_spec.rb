require "rails_helper"

describe PR::Common::SustainedAnalyticsService do
  describe ".perform" do
    context "when shop's current time period is installed" do
      let!(:shop) { create(:shop, :with_user) }
      let(:current_time_period) { shop.current_time_period }
      let(:current_time) { Time.zone.local(2018, 1, 14, 0, 0, 1) }

      around { |example| Timecop.freeze(current_time, &example.method(:run)) }

      context "when time period started under 7 days ago and shop_retained_analytic_sent_at is nil" do
        before { current_time_period.update!(start_time: current_time) }

        it "does not send an identify analytic" do
          expect(Analytics).not_to receive(:identify)

          described_class.perform
        end

        it "does not send a track analytic" do
          expect(Analytics).not_to receive(:track)

          described_class.perform
        end

        it "does not change the time period's shop_retained_analytic_sent_at" do
          expect { described_class.perform }
            .not_to change(current_time_period, :shop_retained_analytic_sent_at)
            .from(nil)
        end
      end

      context "when time period was started over 7 days ago and shop_retained_analytic_sent_at is nil" do
        before { current_time_period.update!(start_time: Time.zone.local(2018, 1, 7)) }

        it "sends an identify analytic" do
          expect(Analytics).to receive(:identify)
            .with(
              user_id: shop.user.id,
              traits: {
                currentDaysInstalled: 8,
                totalDaysInstalled: 8
              }
            )

          described_class.perform
        end

        it "sends a track analytic" do
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

          described_class.perform
        end

        it "updates the time period's shop_retained_analytic_sent_at to the current time" do
          expect { described_class.perform }
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

          described_class.perform
        end

        it "does not send a track analytic" do
          expect(Analytics).not_to receive(:track)

          described_class.perform
        end

        it "does not change the time period's shop_retained_analytic_sent_at" do
          expect { described_class.perform }
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

          described_class.perform
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


          described_class.perform
        end

        it "updates the time period's shop_retained_analytic_sent_at to the current time" do
          expect { described_class.perform }
            .to change { current_time_period.reload.shop_retained_analytic_sent_at }
            .to(current_time)
        end
      end
    end
  end
end
