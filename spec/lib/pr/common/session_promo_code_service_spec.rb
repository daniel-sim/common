require "rails_helper"

describe SessionPromoCodeService do
  subject(:service) { described_class.new(session) }

  let(:code) { "THE-CODE" }
  let(:promo_code) { PR::Common::Models::PromoCode.create(code: code) }
  let(:shop) { create(:shop) }
  let(:session) { {} }

  describe "#maybe_apply_to_shop" do
    context "when no code is in session" do
      it "does not apply" do
        expect { service.maybe_apply_to_shop(shop) }
          .not_to change(shop, :promo_code)
      end
    end

    context "when the promo code in session does not exist" do
      before { session[:promo_code] = "non-existant code" }

      it "does not apply" do
        expect { service.maybe_apply_to_shop(shop) }
          .not_to change(shop, :promo_code)
      end
    end

    context "when the promo code in session does exist" do
      before { session[:promo_code] = code }

      context "when the promo code is expired" do
        around do |example|
          Timecop.freeze do
            promo_code.update!(expires_at: Time.current)
            example.run
          end
        end

        it "does not apply the code" do
          expect { service.maybe_apply_to_shop(shop) }
            .not_to change(shop, :promo_code)
            .from(nil)
        end
      end

      context "when the shop has no promo code" do
        it "applies the code" do
          expect { service.maybe_apply_to_shop(shop) }
            .to change(shop, :promo_code)
            .from(nil)
            .to(promo_code)
        end
      end

      context "when the shop already has a promo code" do
        let(:existing_promo_code) { PR::Common::Models::PromoCode.create(code: "EXISTING-PROMO-CODE") }
        before { shop.update!(promo_code: existing_promo_code) }

        it "overwrites the old code" do
          expect { service.maybe_apply_to_shop(shop) }
            .to change(shop, :promo_code)
            .from(existing_promo_code)
            .to(promo_code)
        end
      end
    end
  end

  describe "#store" do
    it "stores the code in session" do
      expect { service.store(promo_code) }
        .to change { session[:promo_code] }
        .from(nil)
        .to(code)
    end
  end

  describe "#clear" do
    it "deletes the promo code from the session" do
      session[:promo_code] = code

      expect { service.clear }
        .to change { session[:promo_code] }
        .from(code)
        .to(nil)
    end
  end
end
