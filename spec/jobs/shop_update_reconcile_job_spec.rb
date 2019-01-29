require "rails_helper"

describe ShopUpdateReconcileJob do
  let(:shop) { create(:shop, user: build(:user)) }
  let(:sustained_analytics_service) { PR::Common::SustainedAnalyticsService.new(shop) }

  around do |example|
    Timecop.freeze(Time.new(2019, 1, 1, 5, 28, 31).in_time_zone) { example.run }
  end

  before do
    allow(Analytics).to receive(:flush)

    allow(PR::Common::SustainedAnalyticsService)
      .to receive(:new)
      .with(shop, current_time: Time.new(2019, 1, 1, 5).in_time_zone) # time at start of the hour
      .and_return(sustained_analytics_service)
  end

  context "when shopify_plan changes from affiliate to frozen" do
    before do
      allow(ShopifyAPI::Shop).to receive(:current).and_return(OpenStruct.new(plan_name: "frozen"))
      allow(Analytics).to receive(:track).with(updated_plan_params)
      allow(Analytics).to receive(:track).with(handed_off_params)
    end

    let(:updated_plan_params) do
      {
        user_id: shop.user.id,
        event: "Shopify Plan Updated",
        properties: {
          email: shop.user.email,
          pre_shopify_plan: "affiliate",
          post_shopify_plan: "frozen"
        }
      }
    end

    let(:handed_off_params) do
      {
        user_id: shop.user.id,
        event: "Shop Handed Off",
        properties: {
          email: shop.user.email,
          shopify_plan: "frozen"
        }
      }
    end

    it "sends a 'Shopify Plan Updated' analytic" do
      expect(Analytics).to receive(:track).with(updated_plan_params)

      described_class.perform_now(shop.id)
    end

    it "sends a 'Shop Handed Off' analytic" do
      expect(Analytics).to receive(:track).with(handed_off_params)

      described_class.perform_now(shop.id)
    end

    it "calls out to SustainedAnalyticsService" do
      expect(sustained_analytics_service).to receive(:perform)

      described_class.perform_now(shop.id)
    end
  end

  context "when shopify_plan changes from affiliate to something other than frozen" do
    before do
      allow(ShopifyAPI::Shop).to receive(:current).and_return(OpenStruct.new(plan_name: "enterprise"))
      allow(Analytics).to receive(:track).with(updated_plan_params)
      allow(Analytics).to receive(:track).with(handed_off_params)
    end

    let(:updated_plan_params) do
      {
        user_id: shop.user.id,
        event: "Shopify Plan Updated",
        properties: {
          email: shop.user.email,
          pre_shopify_plan: "affiliate",
          post_shopify_plan: "enterprise"
        }
      }
    end

    let(:handed_off_params) do
      {
        user_id: shop.user.id,
        event: "Shop Handed Off",
        properties: {
          email: shop.user.email,
          shopify_plan: "enterprise"
        }
      }
    end

    it "sends a 'Shopify Plan Updated' analytic" do
      expect(Analytics).to receive(:track).with(updated_plan_params)

      described_class.perform_now(shop.id)
    end

    it "does not send a 'Shop Handed Off' analytic" do
      expect(Analytics).not_to receive(:track).with(handed_off_params)

      described_class.perform_now(shop.id)
    end


    it "calls out to SustainedAnalyticsService" do
      expect(sustained_analytics_service).to receive(:perform)

      described_class.perform_now(shop.id)
    end
  end


  context "when shopify_plan does not change" do
    before do
      allow(ShopifyAPI::Shop).to receive(:current).and_return(OpenStruct.new(plan_name: shop.shopify_plan))
    end

    it "does not send any analytics" do
      expect(Analytics).not_to receive(:track)

      described_class.perform_now(shop.id)
    end

    it "calls out to SustainedAnalyticsService" do
      expect(sustained_analytics_service).to receive(:perform)

      described_class.perform_now(shop.id)
    end
  end

  context "when reconcilliation fails" do
    before do
      allow(ShopifyAPI::Shop)
        .to receive(:current)
        .and_raise(ActiveResource::ClientError, OpenStruct.new(code: '402'))
    end

    it "does not call out to SustainedAnalyticsService" do
      expect(sustained_analytics_service).to receive(:perform)

      described_class.perform_now(shop.id)
    end
  end
end
