require "rails_helper"

describe ShopUpdateJob do
  let(:shop) { create(:shop, user: build(:user)) }

  before { allow(Analytics).to receive(:flush) }

  describe "#perform" do
    context "when plan_name of the shop has changed to frozen" do
      it "sends a 'Shop Handed Off' analytic" do
        analytic_params = {
          event: "Shop Handed Off",
          userId: shop.user.id,
          properties: {
            email: shop.user.email,
          }
        }

        expect(Analytics).to receive(:track) { analytic_params }

        described_class.perform_now(
          shop_domain: shop.shopify_domain,
          webhook: {
            plan_name: "frozen"
          }
        )
      end
    end

    context "when plan_name of the shop has not changed" do
      it "does not send an analytic" do
        expect(Analytics).not_to receive(:track)

        described_class.perform_now(
          shop_domain: shop.shopify_domain,
          webhook: {
            plan_name: shop.plan_name
          }
        )
      end
    end
  end
end
