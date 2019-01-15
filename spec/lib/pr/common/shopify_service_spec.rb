require "rails_helper"

describe PR::Common::ShopifyService do
  subject(:service) { described_class.new(shop: shop) }

  let(:shop) { create(:shop, user: build(:user)) }

  describe "#determine_price" do
    context "when shop has a plan whose pricing is defined" do
      before { shop.update!(plan_name: "affiliate") }

      it "returns the defined price" do
        expected_price = {
          price: 0,
          trial_days: 0,
          plan_name: "affiliate",
          name: "Affiliate",
          terms: "Affiliate terms"
        }

        expect(service.determine_price).to eq expected_price
      end
    end

    context "when shop has no plan whose pricing is defined" do
      before { shop.update!(plan_name: "foobar") }

      it "returns the pricing plan without a plan name" do
        expected_price = {
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

        it "sets plan_name to frozen" do
          expect(shop.plan_name).to eq "affiliate"
          service.reconcile_with_shopify
          expect(shop.reload.plan_name).to eq "frozen"
        end
      end

      context "where error is a 404" do
        let(:code) { 404 }

        context "when shop is an affiliate" do
          it "sets plan_name to cancelled" do
            expect(shop.plan_name).to eq "affiliate"
            service.reconcile_with_shopify
            expect(shop.reload.plan_name).to eq "cancelled"
          end

          it "does not call track_cancelled" do
            expect(service).not_to receive(:track_cancelled)

            service.reconcile_with_shopify
          end
        end

        context "when shop is not an affiliate" do
          before { shop.update!(plan_name: "basic") }

          it "sets plan_name to cancelled" do
            service.reconcile_with_shopify
            expect(shop.reload.plan_name).to eq "cancelled"
          end

          it "calls track_cancelled" do
            expect(service).to receive(:track_cancelled)

            service.reconcile_with_shopify
          end
        end
      end

      context "when error is a 420" do
        let(:code) { 420 }

        it "sets plan_name to 🌲" do
          expect(shop.plan_name).to eq "affiliate"
          service.reconcile_with_shopify
          expect(shop.reload.plan_name).to eq "🌲"
        end
      end

      context "when error is a 423" do
        let(:code) { 423 }

        it "sets plan_name to locked" do
          expect(shop.plan_name).to eq "affiliate"
          service.reconcile_with_shopify
          expect(shop.reload.plan_name).to eq "locked"
        end
      end
    end
  end

  describe "#track_reopened" do
    let(:analytic_params) do
      {
        user_id: shop.user.id,
        event: "Shop Reopened",
        properties: {
          "registration method": "shopify",
          email: shop.user.email
        }
      }
    end

    it "sends an 'Shop Reopened' analytic" do
      expect(Analytics).to receive(:track) { analytic_params }

      service.track_reopened
    end
  end

  describe "#track_reinstalled" do
    let(:analytic_params) do
      {
        user_id: shop.user.id,
        event: "App Reinstalled",
        properties: {
          "registration method": "shopify",
          email: shop.user.email
        }
      }
    end

    it "sends an 'App Reinstalled' analytic" do
      expect(Analytics).to receive(:track) { analytic_params }

      service.track_reinstalled
    end
  end

  describe "#track_uninstalled" do
    let(:analytic_params) do
      {
        user_id: shop.user.id,
        event: "App Uninstalled",
        properties: {
          email: shop.user.email,
          activeCharge: false,
          subscription_length: nil
        }
      }
    end

    it "sends an 'App Uninstalled' analytic" do
      expect(Analytics).to receive(:track) { analytic_params }

      service.track_uninstalled
    end
  end

  describe "#track_handed_off" do
    let(:analytic_params) do
      {
        user_id: shop.user.id,
        event: "Shop Handed Off",
        properties: {
          plan_name: "enterprise",
          email: shop.user.email
        }
      }
    end

    it "sends an 'App Handed Off' analytic" do
      expect(Analytics).to receive(:track) { analytic_params }

      service.track_handed_off("enterprise")
    end
  end

  describe "#track_cancelled" do
    let(:analytic_params) do
      {
        user_id: shop.user.id,
        event: "Shop Closed",
        properties: {
          subscription_length: shop.user.subscription_length
        }
      }
    end

    it "sends a 'Shop Closed' analytic" do
      expect(Analytics).to receive(:track) { analytic_params }

      service.track_cancelled
    end
  end

  describe "#track_installed" do
    let(:analytic_params) do
      {
        user_id: shop.user.id,
        event: "App Installed",
        properties: {
          "registration method": "shopify",
          email: shop.user.email
        }
      }
    end

    it "sends an 'App Reinstalled' analytic" do
      expect(Analytics).to receive(:track) { analytic_params }

      service.track_installed
    end
  end
end
