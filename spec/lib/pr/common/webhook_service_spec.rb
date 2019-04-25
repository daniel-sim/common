require "rails_helper"

describe PR::Common::WebhookService do
  let(:shop) { create(:shop) }
  let(:uninstalled_shop) { create(:shop, :uninstalled) }
  let(:existing_api_webhooks) do
    [
      OpenStruct.new(
        id: 1,
        address: "https://localhost:3000/webhooks/shop_update",
        topic: "shop/update",
        created_at: "2018-10-09T08:08:15-04:00",
        updated_at: "2018-10-09T08:08:15-04:00",
        format: "json",
        fields: [],
        metafield_namespaces: []
      ),
      OpenStruct.new(
        id: 2,
        address: "https://localhost:3000/webhooks/app_uninstalled",
        topic: "app/uninstalled",
        created_at: "2018-10-09T08:08:15-04:00",
        updated_at: "2018-10-09T08:08:15-04:00",
        format: "json",
        fields: [],
        metafield_namespaces: []
      )
    ]
  end
  let(:configured_webhooks) do
    [
      {
        topic: "app/installed",
        address: "https://localhost:3000/webhooks/app_installed",
        format: "json"
      },
      {
        topic: "app/uninstalled",
        address: "https://localhost:3000/webhooks/app_uninstalled",
        format: "json"
      }
    ]
  end

  describe ".recreate_webhooks!" do
    it "creates a new instance for installed shops only" do
      service_shop = described_class.new(shop)

      expect(described_class)
        .to receive(:new)
        .with(shop)
        .and_return service_shop

      expect(described_class)
        .not_to receive(:new)
        .with(uninstalled_shop)

      described_class.recreate_webhooks!
    end
  end

  subject(:service) { described_class.new(shop) }

  describe "#recreate_webhooks!" do
    before do
      allow(ShopifyApp.configuration).to receive(:webhooks) { configured_webhooks }
      allow(ShopifyAPI::Webhook).to receive(:all) { existing_api_webhooks }
      allow(ShopifyAPI::Webhook).to receive(:delete).with(existing_api_webhooks.first)
      allow(ShopifyAPI::Webhook).to receive(:create).with(configured_webhooks.first)
    end

    it "requests all existing webhooks" do
      expect(ShopifyAPI::Webhook).to receive(:all)

      service.recreate_webhooks!
    end

    it "creates new webhooks that do not already exist" do
      expect(ShopifyAPI::Webhook).to receive(:create).with(configured_webhooks.first)

      service.recreate_webhooks!
    end

    it "does not create webhooks that already exist" do
      expect(ShopifyAPI::Webhook).not_to receive(:create).with(configured_webhooks.second)

      service.recreate_webhooks!
    end

    it "deletes existing webhooks that are not configured" do
      expect(ShopifyAPI::Webhook).to receive(:delete).with(existing_api_webhooks.first.id)

      service.recreate_webhooks!
    end

    it "does not delete existing webhooks that are also configured" do
      expect(ShopifyAPI::Webhook).not_to receive(:delete).with(existing_api_webhooks.second.id)

      service.recreate_webhooks!
    end

    error_classes = [
      ActiveResource::UnauthorizedAccess,
      ActiveResource::ConnectionError,
      Timeout::Error,
      OpenSSL::SSL::SSLError,
      Exception
    ]

    error_classes.each do |error_class|
      context "when a #{error_class} occurs" do
        let(:error) { error_class.new("fail") }

        before do
          allow(ShopifyAPI::Webhook).to receive(:all) { raise error }
        end

        it "catches the error" do
          expect { service.recreate_webhooks! }.not_to raise_error
        end

        it "logs an error" do
          expect(Rails.logger).to receive(:error)

          service.recreate_webhooks!
        end

        it "returns false" do
          expect(service.recreate_webhooks!).to eq false
        end
      end
    end
  end
end
