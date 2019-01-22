require "rails_helper"

describe ShopUpdateReconcileJob do
  let(:shop) { create(:shop, user: build(:user)) }
  let(:sustained_analytics_service) { PR::Common::SustainedAnalyticsService.new(shop) }


  before do
    allow(Analytics).to receive(:flush)

    allow(PR::Common::SustainedAnalyticsService)
      .to receive(:new)
      .with(shop)
      .and_return(sustained_analytics_service)
  end

  context "when shopify_plan changes from affiliate to frozen" do
    before do
      allow(ShopifyAPI::Shop).to receive(:current).and_return(OpenStruct.new(plan_name: "frozen"))
    end

    it "sends a 'Shop Handed Off' analytic" do
      analytic_params = {
        event: "Shop Handed Off",
        userId: shop.user.id,
        properties: {
          email: shop.user.email
        }
      }

      expect(Analytics).to receive(:track) { analytic_params }

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
    end

    it "does not send an analytic" do
      expect(Analytics).not_to receive(:track)

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

    it "does not send an analytic" do
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
