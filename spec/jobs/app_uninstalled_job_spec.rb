require 'rails_helper'

describe AppUninstalledJob do
  let(:shop) { create(:shop, user: build(:user)) }

  before { allow(Analytics).to receive(:flush) }

  describe "#perform" do
    it "set the shop to uninstalled" do
      expect { described_class.perform_now(shop_domain: shop.shopify_domain) }
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
          activeCharge: false,
          subscription_length: nil
        }
      }

      expect(Analytics).to receive(:track) { analytic_params }

      described_class.perform_now(shop_domain: shop.shopify_domain)
    end
  end
end
