require 'rails_helper'

describe ShopUpdateJob do
  let(:shop) { create(:shop, user: build(:user)) }

  context 'plan_name of the shop has changed' do
    it 'sends analytics request', vcr: { cassette_name: 'shop_update_job' } do
      described_class.perform_now({
        shop_domain: shop.shopify_domain,
        webhook: {
          plan_name: 'enterprise'
        }
      })
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
    it 'sends analytics request', vcr: { cassette_name: 'shop_update_job' } do
      described_class.perform_now({
        shop_domain: shop.shopify_domain,
        webhook: {
          plan_name: shop.plan_name
        }
      })
      expect(WebMock).to_not have_requested(:post, 'https://api.segment.io/v1/import')
    end
  end
end
