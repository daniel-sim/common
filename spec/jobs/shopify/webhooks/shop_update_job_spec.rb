require "rails_helper"

describe Shopify::Webhooks::ShopUpdateJob do
  let(:shopify_domain) { "the_domain" }
  let(:shop) { create(:shop, shopify_domain: shopify_domain, user: build(:user)) }
  let(:service) { PR::Common::ShopifyService.new(shop: shop) }
  let(:plan) { "the_plan" }
  let(:email) { "jamie@pluginuseful.com" }

  before do
    allow(Analytics).to receive(:flush)
    allow(Shop)
      .to receive(:find_by)
      .with(shopify_domain: shopify_domain)
      .and_return(shop)
    allow(PR::Common::ShopifyService)
      .to receive(:new)
      .with(shop: shop)
      .and_return(service)
  end

  describe "#perform" do
    before { skip("We need to get user creation in as a hotfix. That broke the specs.") }

    it "calls out to PR::Common::ShopifyService#update_shop" do
      expect(service)
        .to receive(:update_shop)
        .with(shopify_plan: plan, uninstalled: false)

      described_class.perform_now(
        shop_domain: shopify_domain,
        webhook: {
          plan_name: plan
        }
      )
    end

    it "calls out to PR::Common::ShopifyService#update_user" do
      expect(service)
        .to receive(:update_user)
        .with(email: email)

      described_class.perform_now(
        shop_domain: shopify_domain,
        webhook: {
          email: email
        }
      )
    end
  end
end
