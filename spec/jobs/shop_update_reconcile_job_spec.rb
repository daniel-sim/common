require 'rails_helper'

describe ShopUpdateReconcileJob do
  let(:shop) { create(:shop, user: build(:user)) }

  context 'plan_name of the shop has changed' do
    before :each do
      allow(ShopifyAPI::Shop).to receive(:current).and_return(OpenStruct.new(plan_name: 'enterprise'))
    end
    it 'sends analytics request', vcr: { cassette_name: 'shop_update_reconcile_job' } do
      described_class.perform_now(shop)
      expect(WebMock).to have_requested(:post, 'https://api.segment.io/v1/import').with(body: hash_including({
        batch: array_including(hash_including(
          {
            "event" => "Shop Handed Off",
            "userId" => shop.user.id,
            "properties" => {
              "email" => shop.user.email,
              "plan_name" => 'enterprise',
            }
          }
        ))
      }))
    end
  end

  context 'plan_name of the shop has not changed' do
    before :each do
      allow(ShopifyAPI::Shop).to receive(:current).and_return(OpenStruct.new(plan_name: shop.plan_name))
    end

    it 'not sends analytics request', vcr: { cassette_name: 'shop_update_reconcile_job' } do
      described_class.perform_now(shop)
      expect(WebMock).to_not have_requested(:post, 'https://api.segment.io/v1/import')
    end
  end
end
