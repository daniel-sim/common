require "rails_helper"
describe PR::Common::SignInService do
  let(:shop) { create(:shop, :with_user) }
  let(:user) { shop.user }

  describe ".track" do
    it "sends tracking analytics" do
      expect(Analytics)
        .to receive(:identify)
        .with(user_id: user.id, traits: { email: user.email, promo_code: nil })

      expect(Analytics)
        .to receive(:track)
        .with(user_id: user.id, event: "Shop Signed In", properties: {
          email: user.email,
          promo_code: nil
        })

      described_class.track(shop)
    end

    context "with a promo code" do
      let(:code) { "THE_CODE" }
      before { shop.create_promo_code!(code: code) }

      it "includes promo codes in tracking details" do
        expect(Analytics)
          .to receive(:identify)
          .with(user_id: user.id, traits: { email: user.email, promo_code: code })

        expect(Analytics)
          .to receive(:track)
          .with(user_id: user.id, event: "Shop Signed In", properties: {
            email: user.email,
            promo_code: code
          })

        described_class.track(shop)
      end
    end
  end
end
