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

      context "when user has just reinstalled" do
        before { allow_any_instance_of(User).to receive(:just_reinstalled?).and_return(true) }

        it "sends an 'App Reinstalled' analytic" do
          expect(Analytics)
            .to receive(:track)
            .with(user_id: user.id,
                  event: "App Reinstalled",
                  properties: {
                    "registration method": "shopify",
                    email: user.email
                  })

          returned_user
        end
      end

      context "when user has not just reinstalled" do
        it "does not send a 'User Reinstalled' analytic" do
          expect(Analytics).not_to receive(:track)

          returned_user
        end
      end

      context "when user has just reopened shop" do
        before { allow_any_instance_of(User).to receive(:just_reopened?).and_return(true) }

        it "sends an 'Shop Reopened' analytic" do
          expect(Analytics)
            .to receive(:track)
            .with(user_id: user.id,
                  event: "Shop Reopened",
                  properties: {
                    "registration method": "shopify",
                    email: user.email
                  })

          returned_user
        end
      end

      context "when user has not just reopened shop" do
        it "does not send a 'User Reopened' analytic" do
          expect(Analytics).not_to receive(:track)

          returned_user
        end
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

      it "sends an 'App Installed' analytic" do
        expect(Analytics).to receive(:track) do
          {
            user_id: created_user.id,
            event: "App Installed",
            properties: {
              "registration method": "shopify",
              email: created_user.email
            }
          }
        end

        created_user
      end
    end
  end
end
