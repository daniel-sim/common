require "rails_helper"

# See spec/dummy/config/initializers/common_initializer.rb for
# test pricing
describe PR::Common::ChargeService do
  let(:user) { create(:user) }
  let(:shop) { create(:shop, user: user) }
  let(:base_url) { "http://localhost" }
  let(:service) { described_class.new(shop) }

  shared_examples "post charge-activation" do
    it "sets the user's active charge to true" do
      expect { subject }
        .to change(user, :active_charge)
        .from(false)
        .to(true)
    end

    it "updates the user's charged_at time to now" do
      Timecop.freeze do
        expect { subject }
          .to change(user, :charged_at)
          .from(nil)
          .to(Time.current)
      end
    end

    it "updates the shop's app_plan to the price key" do
      expect { subject }
        .to change(shop, :app_plan)
        .from(nil)
        .to(described_class.determine_app_plan_from_charge(charge).to_s)
    end

    it "sends an identify analytic" do
      expect(Analytics).to receive(:identify)
        .with(
          user_id: user.id,
          traits: {
            email: user.email,
            monthlyUsd: charge.price,
            appPlan: described_class.determine_app_plan_from_charge(charge),
            trial: price.positive?,
            promo_code: false
          }
        )

      subject
    end

    it "sends a 'Charge Activated' track analytic" do
      expect(Analytics).to receive(:track)
        .with(
          user_id: user.id,
          event: "Charge Activated",
          properties: {
            email: user.email,
            monthly_usd: charge.price,
            app_plan: described_class.determine_app_plan_from_charge(charge),
            promo_code: false
          }
        )

      subject
    end
  end

  describe ".determine_app_plan_from_charge" do
    context "when the app plan exists" do
      let(:charge) { ShopifyAPI::RecurringApplicationCharge.new(name: "Staff Business") }

      it "returns the charge's key" do
        expect(described_class.determine_app_plan_from_charge(charge)).to eq :staff_business_free
      end
    end

    context "when the app plan does not exist" do
      let(:charge) { ShopifyAPI::RecurringApplicationCharge.new(name: "foobar") }

      it "returns nil" do
        expect(described_class.determine_app_plan_from_charge(charge)).to be_nil
      end
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
          allow(ShopifyAPI::RecurringApplicationCharge)
            .to receive(:current)
            .and_return fake_recurring_application_charge
        end

        it "cancels it" do
          expect(fake_recurring_application_charge).to receive(:cancel)

          subject
        end
      end

      context "when there is no existing charge" do
        it "does not try to cancel it" do
          expect { subject }.not_to raise_error
        end
      end
    end

    context "when price is 0" do
      let(:price) { 0 }
      let(:charge) { ShopifyAPI::RecurringApplicationCharge.new(price: price, name: "Affiliate") }

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
    let(:charge) { ShopifyAPI::RecurringApplicationCharge.new(price: price, name: "Generic with trial") }

    include_examples "post charge-activation"

    it "activates the charge" do
      expect(charge).to receive(:activate)

      subject
    end
  end

  describe "#up_to_date_price" do
    it "calls out to 'PR::Common::ShopifyService#determine_price' with return from Shopify API" do
      api_shop = ShopifyAPI::Shop.new(plan_name: "foo")
      fake_service = PR::Common::ShopifyService.new(shop: shop)

      allow(ShopifyAPI::Shop)
        .to receive(:current)
        .and_return(api_shop)

      allow(PR::Common::ShopifyService)
        .to receive(:new)
        .with(shop: shop)
        .and_return(fake_service)

      expect(fake_service)
        .to receive(:determine_price)
        .with(api_shop: api_shop)

      described_class.new(shop).up_to_date_price
    end
  end
end
