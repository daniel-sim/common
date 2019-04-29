require 'rails_helper'

describe Shopify::Webhooks::AppUninstalledJob do
  let(:shop) { create(:shop, user: build(:user)) }

  before { allow(Analytics).to receive(:flush) }

  describe "#perform" do
    it "set the shop to uninstalled" do
      expect { described_class.perform_now(shop_domain: shop.shopify_domain, webhook: nil) }
        .to change { shop.reload.uninstalled }
        .from(false)
        .to(true)
    end

    it "sends an 'App Uninstalled' analytic" do
      analytic_params = {
        user_id: shop.user.id,
        event: "App Uninstalled",
        properties: {
          email: shop.user.email,
          subscription_length: nil,
          current_days_installed: 1,
          total_days_installed: 1,
          current_periods_paid: 0,
          total_periods_paid: 0,
          monthly_usd: 0.0,
          current_usd_paid: 0.0,
          total_usd_paid: 0.0
        }
      }

      expect(Analytics).to receive(:track).with(analytic_params)

      described_class.perform_now(shop_domain: shop.shopify_domain)
    end
  end
end
