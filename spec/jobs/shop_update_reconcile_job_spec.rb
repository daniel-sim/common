require "rails_helper"

describe ShopUpdateReconcileJob do
  let(:shop) { create(:shop, user: build(:user)) }

  before { allow(Analytics).to receive(:flush) }

  context "when plan_name changes from affiliate to frozen" do
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

      described_class.perform_now(shop)
    end
  end

  context "when plan_name changes from affiliate to something other than frozen" do
    before do
      allow(ShopifyAPI::Shop).to receive(:current).and_return(OpenStruct.new(plan_name: "enterprise"))
    end

    it "does not send an analytic" do
      expect(Analytics).not_to receive(:track)

      described_class.perform_now(shop)
    end
  end


  context "when plan_name does not change" do
    before do
      allow(ShopifyAPI::Shop).to receive(:current).and_return(OpenStruct.new(plan_name: shop.plan_name))
    end

    it "does not send an analytic" do
      expect(Analytics).not_to receive(:track)

      described_class.perform_now(shop)
    end
  end
end
