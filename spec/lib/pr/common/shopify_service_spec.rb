require 'rails_helper'

describe PR::Common::ShopifyService do
  let(:shop) { create(:shop, user: build(:user)) }
  subject(:service) { described_class.new(shop: shop) }

  describe '#determine_price' do
    context 'shop has a plan whose pricing is defined' do
      before { shop.update!(plan_name: 'affiliate') }

      it 'returns the defined price' do
        expected_price = {
          price:      0,
          trial_days: 0,
          plan_name:  'affiliate',
          name:       'Affiliate',
          terms:      'Affiliate terms',
        }

        expect(service.determine_price).to eq expected_price
      end
    end

    context 'shop has no plan whose pricing is defined' do
      before { shop.update!(plan_name: 'foobar') }

      it 'returns the pricing plan without a plan name' do

        expected_price = {
          price:      10.0,
          trial_days: 7,
          name:       'Generic with trial',
          terms:      'Generic terms',
        }

        expect(service.determine_price).to eq expected_price
      end
    end
  end

  describe '#reconcile_with_shopify' do
    context 'shop response errors' do
      before :each do
        allow(ShopifyAPI::Shop).to receive(:current).and_raise(ActiveResource::ClientError.new(OpenStruct.new(code: code)))
        allow(Analytics).to receive(:track)
      end

      context 'with 402' do
        let(:code) { 402 }
        it 'sets plan_name to frozen' do
          expect(shop.plan_name).to eq 'affiliate'
          service.reconcile_with_shopify
          expect(shop.reload.plan_name).to eq 'frozen'
        end
      end

      context 'with 404' do
        let(:code) { 404 }
        it 'sets plan_name to cancelled' do
          expect(shop.plan_name).to eq 'affiliate'
          service.reconcile_with_shopify
          expect(shop.reload.plan_name).to eq 'cancelled'
        end
      end

      context 'with 420' do
        let(:code) { 420 }
        it 'sets plan_name to 🌲' do
          expect(shop.plan_name).to eq 'affiliate'
          service.reconcile_with_shopify
          expect(shop.reload.plan_name).to eq '🌲'
        end
      end

      context 'with 423' do
        let(:code) { 423 }
        it 'sets plan_name to locked' do
          expect(shop.plan_name).to eq 'affiliate'
          service.reconcile_with_shopify
          expect(shop.reload.plan_name).to eq 'locked'
        end
      end
    end
  end

  describe "#update_shop" do
    before { allow(Analytics).to receive(:track) }

    context "when shop should not have a fake plan" do
      context "in staging" do
        before do
          allow(Rails.env).to receive(:production?).and_return(false)
        end

        it "does not fake the plan_name" do
          service.update_shop(plan_name: "affiliate", uninstalled: true)
          expect(shop.plan_name).to eq "affiliate"
        end
      end
    end

    context "when faked shop should be staff_business" do
      before do
        shop.update!(shopify_domain: "hello-ladies_plan-staff_business.myshopify.com")
      end

      context "in production" do
        before { allow(Rails.env).to receive(:production?).and_return(true) }
        it "does not fake the plan_name" do
          service.update_shop(plan_name: "affiliate", uninstalled: true)
          expect(shop.plan_name).to eq "affiliate"
        end
      end

      context "in staging" do
        before do
          allow(Rails.env).to receive(:production?).and_return(false)
        end
        it "does fake the plan_name" do
          service.update_shop(plan_name: "affiliate", uninstalled: true)
          expect(shop.plan_name).to eq "staff_business"
        end
      end
    end
  end
end
