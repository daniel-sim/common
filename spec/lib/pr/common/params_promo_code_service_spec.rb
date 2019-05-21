require "rails_helper"

describe ParamsPromoCodeService do
  subject(:service) { described_class.new(params) }

  let(:code) { "THE-CODE" }
  let(:promo_code) { PR::Common::Models::PromoCode.create(code: code) }
  let(:params) { { promo_code: code } }

  describe "#record" do
    before { promo_code }

    it "returns the promo code record from the DB matching the code in params" do
      expect(service.record).to eq promo_code
    end
  end

  describe "error" do
    context "when the promo code exists" do
      before { promo_code }

      it "returns nil" do
        expect(service.error).to eq nil
      end
    end

    context "when the promo code does not exist" do
      it "returns invalid promo code text" do
        expect(service.error).to eq "Invalid promo code."
      end
    end
  end

  describe "#present?" do
    context "when the promo code exists" do
      before { promo_code }

      it "returns true" do
        expect(service.present?).to eq true
      end
    end

    context "when there is no such promo code" do
      it "returns false" do
        expect(service.present?).to eq false
      end
    end
  end

  describe "#code" do
    it "returns the code from the params" do
      expect(service.code).to eq code
    end
  end
end
