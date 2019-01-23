require "rails_helper"

describe PR::Common::UserService do
  describe "#find_or_create_user_by_shopify" do
    subject(:service) { PR::Common::UserService.new }
    let(:shop) { create(:shop) }

    context "when user exists" do
      let(:user) { create(:user, username: "shopify-#{shop.shopify_domain}", shop: shop) }
      let(:returned_user) do
        service.find_or_create_user_by_shopify(email: user.email, shop: shop)
      end

      it "returns that user" do
        expect(returned_user.id).to eq user.id
      end
    end

    context "when user does not exist" do
      let(:created_user) do
        service.find_or_create_user_by_shopify(email: "jamie@pluginuseful.com", shop: shop)
      end

      it "creates and returns a new user" do
        created_user

        expect(Shop.count).to eq 1
        expect(created_user.username).to eq "shopify-#{shop.shopify_domain}"
        expect(created_user.password).not_to be_blank
        expect(created_user.provider).to eq "shopify"
        expect(created_user.website).to eq shop.shopify_domain
        expect(created_user.shop_id).to eq shop.id
        expect(created_user.email).to eq "jamie@pluginuseful.com"
      end

      it "tracks installation via ShopifyService" do
        shopify_service = PR::Common::ShopifyService.new(shop: shop)

        allow(PR::Common::ShopifyService)
          .to receive(:new)
          .with(shop: shop)
          .and_return(shopify_service)

        expect(shopify_service)
          .to receive(:track_installed)

        created_user
      end
    end
  end
end
