require "rails_helper"

describe PR::Common::ShopifyService do
  subject(:service) { described_class.new(shop: shop) }

  let(:shop) { create(:shop, user: build(:user)) }

  describe "#determine_price" do
    context "when shop has a plan whose pricing is defined" do
      before { shop.update!(shopify_plan: "affiliate") }

      it "returns the defined price" do
        expected_price = {
          key: :affiliate_free,
          price: 0,
          trial_days: 0,
          shopify_plan: "affiliate",
          name: "Affiliate",
          terms: "Affiliate terms"
        }

        expect(service.determine_price).to eq expected_price
      end
    end

    context "when shop has no plan whose pricing is defined" do
      before { shop.update!(shopify_plan: "foobar") }

      it "returns the pricing plan without a plan name" do
        expected_price = {
          key: :generic,
          price: 10.0,
          trial_days: 7,
          name: "Generic with trial",
          terms: "Generic terms"
        }

        expect(service.determine_price).to eq expected_price
      end
    end
  end

  describe "#reconcile_with_shopify" do
    context "when shop response has an error" do
      before do
        allow(ShopifyAPI::Shop)
          .to receive(:current)
          .and_raise(ActiveResource::ClientError.new(OpenStruct.new(code: code)))
        allow(Analytics).to receive(:track)
      end

      context "where error is a 402" do
        let(:code) { 402 }

        it "sets shopify_plan to frozen" do
          expect(shop.shopify_plan).to eq "affiliate"
          service.reconcile_with_shopify
          expect(shop.reload.shopify_plan).to eq "frozen"
        end
      end

      context "where error is a 404" do
        let(:code) { 404 }

        context "when shop is an affiliate" do
          it "sets shopify_plan to cancelled" do
            expect(shop.shopify_plan).to eq "affiliate"
            service.reconcile_with_shopify
            expect(shop.reload.shopify_plan).to eq "cancelled"
          end
        end

        context "when shop is not an affiliate" do
          before { shop.update!(shopify_plan: "basic") }

          it "sets shopify_plan to cancelled" do
            service.reconcile_with_shopify
            expect(shop.reload.shopify_plan).to eq "cancelled"
          end

          it "calls track_cancelled" do
            expect(service).to receive(:track_cancelled)

            service.reconcile_with_shopify
          end
        end
      end

      context "when error is a 420" do
        let(:code) { 420 }

        it "sets shopify_plan to 🌲" do
          expect(shop.shopify_plan).to eq "affiliate"
          service.reconcile_with_shopify
          expect(shop.reload.shopify_plan).to eq "🌲"
        end
      end

      context "when error is a 423" do
        let(:code) { 423 }

        it "sets shopify_plan to locked" do
          expect(shop.shopify_plan).to eq "affiliate"
          service.reconcile_with_shopify
          expect(shop.reload.shopify_plan).to eq "locked"
        end
      end
    end
  end

  describe "#track_reopened" do
    it "sends an identify analytic" do
      analytic_params = {
        user_id: shop.user.id,
        traits: {
          shopifyPlan: "affiliate"
        }
      }

      expect(Analytics).to receive(:identify).with(analytic_params)

      service.track_reopened
    end

    it "sends an 'Shop Reopened' track analytic" do
      analytic_params = {
        user_id: shop.user.id,
        event: "Shop Reopened",
        properties: {
          "registration method": "shopify",
          email: shop.user.email
        }
      }

      expect(Analytics).to receive(:track) { analytic_params }

      service.track_reopened
    end
  end

  describe "#track_reinstalled" do
    it "sends an identify analytic" do
      analytic_params = {
        user_id: shop.user.id,
        traits: {
          shopifyPlan: "affiliate"
        }
      }

      expect(Analytics).to receive(:identify).with(analytic_params)

      service.track_reinstalled
    end

    it "sends an 'App Reinstalled' analytic" do
      analytic_params = {
        user_id: shop.user.id,
        event: "App Reinstalled",
        properties: {
          "registration method": "shopify",
          email: shop.user.email,
          shopify_plan: "affiliate"
        }
      }

      expect(Analytics).to receive(:track).with(analytic_params)

      service.track_reinstalled
    end
  end

  describe "#track_uninstalled" do
    it "sends an identify analytic" do
      analytic_params = {
        user_id: shop.user.id,
        traits: {
          subscriptionLength: nil,
          currentDaysInstalled: shop.current_time_period.lapsed_days,
          totalDaysInstalled: shop.total_days_installed,
          currentPeriodsPaid: shop.current_time_period.periods_paid,
          totalPeriodsPaid: shop.total_periods_paid,
          monthlyUsd: shop.current_time_period.monthly_usd.to_f,
          currentUsdPaid: shop.current_time_period.usd_paid.to_f,
          totalUsdPaid: shop.total_usd_paid.to_f
        }
      }
      expect(Analytics).to receive(:identify).with(analytic_params)

      service.track_uninstalled
    end

    it "sends an 'App Uninstalled' analytic" do
      analytic_params = {
        user_id: shop.user.id,
        event: "App Uninstalled",
        properties: {
          email: shop.user.email,
          subscription_length: nil,
          current_days_installed: shop.current_time_period.lapsed_days,
          total_days_installed: shop.total_days_installed,
          current_periods_paid: shop.current_time_period.periods_paid,
          total_periods_paid: shop.total_periods_paid,
          monthly_usd: shop.current_time_period.monthly_usd.to_f,
          current_usd_paid: shop.current_time_period.usd_paid.to_f,
          total_usd_paid: shop.total_usd_paid.to_f
        }
      }

      expect(Analytics).to receive(:track).with(analytic_params)

      service.track_uninstalled
    end
  end

  describe "#track_handed_off" do
    it "sends an identify analytic" do
      analytic_params = {
        user_id: shop.user.id,
        traits: {
          shopifyPlan: "enterprise"
        }
      }

      expect(Analytics).to receive(:identify).with(analytic_params)

      service.track_handed_off("enterprise")
    end

    it "sends an 'App Handed Off' track analytic" do
      analytic_params = {
        user_id: shop.user.id,
        event: "Shop Handed Off",
        properties: {
          email: shop.user.email,
          shopify_plan: "enterprise"
        }
      }

      expect(Analytics).to receive(:track).with(analytic_params)

      service.track_handed_off("enterprise")
    end
  end

  describe "#track_cancelled" do
    it "sends an identify analytic" do
      analytic_params = {
        user_id: shop.user.id,
        traits: {
          subscriptionLength: shop.user.subscription_length,
          currentDaysInstalled: shop.current_time_period.lapsed_days,
          totalDaysInstalled: shop.total_days_installed,
          currentPeriodsPaid: shop.current_time_period.periods_paid,
          totalPeriodsPaid: shop.total_periods_paid,
          monthlyUsd: shop.current_time_period.monthly_usd.to_f,
          currentUsdPaid: shop.current_time_period.usd_paid.to_f,
          totalUsdPaid: shop.total_usd_paid.to_f
        }
      }

      expect(Analytics).to receive(:identify).with(analytic_params)

      service.track_cancelled
    end

    it "sends a 'Shop Closed' track analytic" do
      analytic_params = {
        user_id: shop.user.id,
        event: "Shop Closed",
        properties: {
          email: shop.user.email,
          subscription_length: shop.user.subscription_length,
          current_days_installed: shop.current_time_period.lapsed_days,
          total_days_installed: shop.total_days_installed,
          current_periods_paid: shop.current_time_period.periods_paid,
          total_periods_paid: shop.total_periods_paid,
          monthly_usd: shop.current_time_period.monthly_usd.to_f,
          current_usd_paid: shop.current_time_period.usd_paid.to_f,
          total_usd_paid: shop.total_usd_paid.to_f
        }
      }

      expect(Analytics).to receive(:track).with(analytic_params)

      service.track_cancelled
    end
  end

  describe "#track_installed" do
    it "sends an identify analytic" do
      analytic_params = {
        user_id: shop.user.id,
        traits: {
          shopifyPlan: "affiliate"
        }
      }

      expect(Analytics).to receive(:identify).with(analytic_params)

      service.track_reinstalled
    end

    it "sends an 'App Reinstalled' track analytic" do
      analytic_params = {
        user_id: shop.user.id,
        event: "App Reinstalled",
        properties: {
          "registration method": "shopify",
          email: shop.user.email,
          shopify_plan: "affiliate"
        }
      }

      expect(Analytics).to receive(:track).with(analytic_params)

      service.track_reinstalled
    end
  end
end
