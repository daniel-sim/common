require "rails_helper"

describe PR::Common::ChargeService do
  let(:user) { create(:user) }
  let(:shop) { create(:shop, user: user) }
  let(:base_url) { "http://localhost" }
  let(:service) { described_class.new(shop) }

  shared_examples "post charge-activation" do
    it "sets active charge to true on the shop's user" do
      expect { subject }
        .to change(user, :active_charge)
        .from(false)
        .to(true)
    end

    it "updates the charged_at time to now" do
      Timecop.freeze do
        expect { subject }
          .to change(user, :charged_at)
          .from(nil)
          .to(Time.current)
      end
    end

    it "sends a 'Charge Activated' analytic" do
      expect(Analytics).to receive(:track)
        .with(
          user_id: user.id,
          event: "Charge Activated",
          properties: {
            monthly_usd: price,
            email: user.email
          }
        )

      subject
    end
  end

  describe "#create_charge" do
    subject { service.create_charge(price, base_url) }

    before do
      allow(ShopifyAPI::RecurringApplicationCharge)
        .to receive(:current)
        .and_return nil

      allow(ShopifyAPI::Shop)
        .to receive(:current)
        .and_return(ShopifyAPI::Shop.new(plan_name: "basic"))

      allow(ShopifyAPI::RecurringApplicationCharge)
        .to receive(:create)
    end

    shared_examples "cancels existing charge" do
      context "when there is an existing charge" do
        let(:fake_recurring_application_charge) { OpenStruct.new(cancel: true) }

        before do
          allow(ShopifyAPI::RecurringApplicationCharge).to receive(:current)
            .and_return fake_recurring_application_charge
        end

        it "cancels it" do
          expect(fake_recurring_application_charge).to receive(:cancel)

          subject
        end
      end

      context "when there no existing charge" do
        it "does not try to cancel it" do
          expect { subject }.not_to raise_error
        end
      end
    end

    context "when price is 0" do
      let(:price) { 0 }

      include_examples "cancels existing charge"
      include_examples "post charge-activation"
    end

    context "when price is above 0" do
      let(:price) { 10.0 }

      include_examples "cancels existing charge"

      it "creates the charge" do
        expect(ShopifyAPI::RecurringApplicationCharge)
          .to receive(:create)
          .with(
            price: price,
            trial_days: 7,
            name: "Generic with trial",
            terms: "Generic terms",
            test: true,
            return_url: "http://localhost/charges/callback?access_token=#{user.access_token}"
          )

        subject
      end
    end
  end

  describe "#activate_charge" do
    subject { service.activate_charge(charge) }
    before { allow(charge).to receive(:activate) }

    let(:price) { 10.0 }
    let(:charge) { ShopifyAPI::RecurringApplicationCharge.new(price: price) }

    include_examples "post charge-activation"

    it "activates the charge" do
      expect(charge).to receive(:activate)

      subject
    end
  end
end
