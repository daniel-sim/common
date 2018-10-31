require 'rails_helper'

describe 'Webhooks' do
  include ActiveJob::TestHelper

  describe 'POST webhooks/customers_redact' do
    def send_request
      data = { type: 'customers_redact' }

      post '/webhooks/customers_redact',
        params: data.to_json,
        headers: {
          'Content-Type' => 'application/json',
          'X-Shopify-Topic' => 'customers/redact',
          'X-Shopify-Hmac-Sha256' => generate_hmac(data.to_json)
        }
    end

    it 'enqueues a CustomersRedactJob' do
      send_request

      expect(CustomersRedactJob).to have_been_enqueued.exactly(:once)
    end
  end

  describe 'POST webhooks/shop_redact' do
    let(:shop) { create(:shop) }

    def send_request
      data = { type: 'shop_redact' }

      post '/webhooks/shop_redact',
        params: data.to_json,
        headers: {
          'Content-Type' => 'application/json',
          'X-Shopify-Topic' => 'shop/redact',
          'X-Shopify-Hmac-Sha256' => generate_hmac(data.to_json),
          'X-Shopify-Shop-Domain' => shop.shopify_domain
        }
    end

    it 'redacts the shop' do
      # We have to stub find_by here or we'll check the
      # redact! call against what is actually a different object
      allow(Shop)
        .to receive(:find_by)
        .with(shopify_domain: shop.shopify_domain)
        .and_return(shop)

      expect(shop).to receive(:redact!).exactly(:once)

      perform_enqueued_jobs { send_request }
    end
  end

  describe 'POST webooks/customers_data_request' do
    def send_request
      data = { type: 'customers_data_request' }

      post '/webhooks/customers_data_request',
        params: data.to_json,
        headers: {
          'Content-Type' => 'application/json',
          'X-Shopify-Topic' => 'customers/data_request',
          'X-Shopify-Hmac-Sha256' => generate_hmac(data.to_json)
        }
    end

    it 'sends out an e-mail with webhook content' do
      perform_enqueued_jobs do
        expect(ActionMailer::Base.deliveries.count).to eq 0

        send_request

        expect(ActionMailer::Base.deliveries.count).to eq 1

        mail = ActionMailer::Base.deliveries.last
        expect(mail.subject).to eq 'Customer Data Request'
        expect(mail.from).to eq [Settings.support_email]
        expect(mail.to).to eq [Settings.support_email]
        expect(mail.body.to_s).to include({
          'topic' => 'customers_data_request',
          'webhook' => {
            'type' => 'customers_data_request'
          }
        }.inspect)
      end
    end
  end
end

