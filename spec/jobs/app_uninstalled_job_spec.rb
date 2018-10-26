require 'rails_helper'

describe AppUninstalledJob do
  let(:shop) { create(:shop, user: build(:user)) }

  it 'sends analytics request', vcr: { cassette_name: 'app_uninstalled' } do
    described_class.perform_now({shop_domain: shop.shopify_domain})
    expect(WebMock).to have_requested(:post, 'https://api.segment.io/v1/import').with(body: hash_including({
      batch: array_including(hash_including(
        {
          "event" => "App Uninstalled",
          "userId" => shop.user.id,
          "properties" => {
            "email" => shop.user.email,
            "activeCharge" => false,
            "subscription_length" => nil
          }
        }
      ))
    }))
  end
end
