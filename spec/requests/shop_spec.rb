require "rails_helper"

describe "Shop" do
  let(:shopify_domain) { "the_domain" }
  let(:shop) { create(:shop, shopify_domain: shopify_domain) }
  let(:service) { PR::Common::ShopifyService.new(shop: shop) }
  let(:plan) { "some new plan" }

  # Temporarily disabled as we now need to test along with omniauth env vars.
  xdescribe "GET shops/callback" do
    let(:url) { "/auth/shopify/callback" }

    before do
      allow(Shop)
        .to receive(:find_by)
        .with(shopify_domain: shopify_domain)
        .and_return(shop)
      allow(PR::Common::ShopifyService)
        .to receive(:new)
        .with(shop: shop)
        .and_return(service)
    end

    it "calls out to PR::Common::ShopifyService.update_shop" do
      expect(service)
        .to receive(:update_shop)
        .with(shopify_plan: plan, uninstalled: shop.uninstalled)

      get url, params: { myshopify_domain: shopify_domain, plan_name: plan }
    end
  end
end
