require "rails_helper"

describe PR::Common::ShopifyService do
  subject(:service) { described_class.new(shop: shop) }

  let(:user) { build(:user) }
  let(:shop) { create(:shop, app_plan: "foobar", user: user) }

  describe "#determine_price" do
    context "when the config's price method is set to a lambda" do
      let(:pricing_method) { -> (shop, args) { [shop, args] } }

      around do |example|
        old_config = PR::Common.config
        new_config = PR::Common::Configuration.new
        new_config.pricing_method = pricing_method

        PR::Common.config = new_config
        example.run

        PR::Common.config = old_config
      end

      it "calls the lambda with the shop and any other args" do
        expect(service.determine_price(foo: :bar)).to eq [shop, foo: :bar]
      end
    end

    context "when shop has a plan whose pricing is defined" do
      before { shop.update!(shopify_plan: "affiliate") }

      it "returns the defined price" do
        expected_price = {
          key: :affiliate_free,
          price: 0,
          trial_days: 0,
          shopify_plan: "affiliate",
          name: "Affiliate",
          terms: "Affiliate terms"
        }

        expect(service.determine_price).to eq expected_price
      end
    end

    context "when shop has no plan whose pricing is defined" do
      before { shop.update!(shopify_plan: "foobar") }

      it "returns the pricing plan without a plan name" do
        expected_price = {
          key: :generic,
          price: 10.0,
          trial_days: 7,
          name: "Generic with trial",
          terms: "Generic terms"
        }

        expect(service.determine_price).to eq expected_price
      end
    end
  end

  describe "#reconcile_with_shopify" do
    context "when shop has no user" do
      let(:shop) { create(:shop, app_plan: "foobar") }

      before do
        allow(ShopifyAPI::Shop)
          .to receive(:current)
          .and_return(ShopifyAPI::Shop.new(plan_name: "basic",
                                           email: "jamie@pluginuseful.com"))
      end

      it "creates a user for it" do
        expect(shop.user).not_to be_present

        service.reconcile_with_shopify

        expect(shop.user).to be_persisted
        expect(shop.user.email).to eq "jamie@pluginuseful.com"
      end
    end

    context "when shop response has an error" do
      before do
        allow(ShopifyAPI::Shop)
          .to receive(:current)
          .and_raise(ActiveResource::ClientError.new(OpenStruct.new(code: code)))
        allow(Analytics).to receive(:track)
      end

      context "where error is a 402" do
        let(:code) { 402 }

        it "sets shopify_plan to frozen" do
          expect(shop.shopify_plan).to eq "affiliate"
          service.reconcile_with_shopify
          expect(shop.reload.shopify_plan).to eq "frozen"
        end
      end

      context "where error is a 404" do
        let(:code) { 404 }

        context "when shop is an affiliate" do
          it "sets shopify_plan to cancelled" do
            expect(shop.shopify_plan).to eq "affiliate"
            service.reconcile_with_shopify
            expect(shop.reload.shopify_plan).to eq "cancelled"
          end
        end

        context "when shop is not an affiliate" do
          before { shop.update!(shopify_plan: "basic") }

          it "sets shopify_plan to cancelled" do
            service.reconcile_with_shopify
            expect(shop.reload.shopify_plan).to eq "cancelled"
          end

          it "calls track_cancelled" do
            expect(service).to receive(:track_cancelled)

            service.reconcile_with_shopify
          end
        end
      end

      context "when error is a 420" do
        let(:code) { 420 }

        it "sets shopify_plan to 🌲" do
          expect(shop.shopify_plan).to eq "affiliate"
          service.reconcile_with_shopify
          expect(shop.reload.shopify_plan).to eq "🌲"
        end
      end

      context "when error is a 423" do
        let(:code) { 423 }

        it "sets shopify_plan to locked" do
          expect(shop.shopify_plan).to eq "affiliate"
          service.reconcile_with_shopify
          expect(shop.reload.shopify_plan).to eq "locked"
        end
      end
    end
  end

  describe "#maybe_update_shopify_plan" do
    context "when shopify plan is unchanged" do
      it "does not track shopify plan updated" do
        expect(service).not_to receive(:track_shopify_plan_updated)

        service.maybe_update_shopify_plan(shop.shopify_plan)
      end
    end

    context "when existing shopify plan is not set" do
      it "does not track shopify plan updated" do
        shop.update!(shopify_plan: nil)

        expect(service).not_to receive(:track_shopify_plan_updated)

        service.maybe_update_shopify_plan("enterprise")
      end
    end

    context "when existing shopify plan differs" do
      it "tracks shopify plan updated" do
        shop.update!(shopify_plan: "enterprise")

        expect(service).to receive(:track_shopify_plan_updated).with("bar")

        service.maybe_update_shopify_plan("bar")
      end
    end
  end

  describe "#maybe_reopen" do
    context "when shop goes from cancelled to another plan" do
      before { shop.update!(shopify_plan: Shop::PLAN_CANCELLED) }

      it "resets charged_at to current time" do
        # This is a smelly test as we don't want to actually update the charged_at, but
        # only set it, as `update_shop` should handle saving.
        # Consider refactoring to test using `update_shop`.
        allow(User).to receive_message_chain("shopify.find_by").and_return(user)

        Timecop.freeze do
          expect(user).to receive(:charged_at=).with(Time.current)

          service.maybe_reopen("business")
        end
      end

      it "sends an identify analytic" do
        analytic_params = {
          user_id: shop.user.id,
          traits: {
            status: :active,
            shopifyPlan: "enterprise"
          }
        }

        expect(Analytics).to receive(:identify).with(analytic_params)

        service.maybe_reopen("enterprise")
      end

      it "sends an 'Shop Reopened' track analytic" do
        analytic_params = {
          user_id: shop.user.id,
          event: "Shop Reopened",
          properties: {
            "registration method": "shopify",
            email: shop.user.email,
            shopify_plan: "enterprise"
          }
        }

        expect(Analytics).to receive(:track).with(analytic_params)

        service.maybe_reopen("enterprise")
      end
    end

    context "when shop is not cancelled" do
      it "does not change charged_at" do
        # This is a smelly test as we don't want to actually update the charged_at, but
        # only set it, as `update_shop` should handle saving.
        # Consider refactoring to test using `update_shop`.
        allow(User).to receive_message_chain("shopify.find_by").and_return(user)

        expect(user).not_to receive(:charged_at=)
        service.maybe_reopen("business")
      end

      it "does not send any analytics" do
        expect(Analytics).not_to receive(:track)
        expect(Analytics).not_to receive(:identify)

        service.maybe_reopen("enterprise")
      end
    end
  end

  describe "#maybe_reinstall_or_uninstall" do
    context "when reinstalling" do
      before do
        shop.update!(uninstalled: true)
        shop.current_time_period.update!(monthly_usd: 50.0)
      end

      it "sends an identify analytic" do
        analytic_params = {
          user_id: shop.user.id,
          traits: {
            status: :active,
            shopifyPlan: "enterprise",
            appPlan: nil, # this gets reset to default
            monthlyUsd: 0 # this gets reset to 0
          }
        }

        expect(Analytics).to receive(:identify).with(analytic_params)

        service.maybe_reinstall_or_uninstall("enterprise", false)
      end

      it "sends an 'App Reinstalled' analytic" do
        analytic_params = {
          user_id: shop.user.id,
          event: "App Reinstalled",
          properties: {
            "registration method": "shopify",
            email: shop.user.email,
            shopify_plan: "enterprise"
          }
        }

        expect(Analytics).to receive(:track).with(analytic_params)

        service.maybe_reinstall_or_uninstall("enterprise", false)
      end
    end

    context "when uninstalling" do
      it "sends an identify analytic" do
        analytic_params = {
          user_id: shop.user.id,
          traits: {
            status: :uninstalled,
            subscriptionLength: nil,
            currentDaysInstalled: shop.current_time_period.lapsed_days,
            totalDaysInstalled: shop.total_days_installed,
            currentPeriodsPaid: shop.current_time_period.periods_paid,
            totalPeriodsPaid: shop.total_periods_paid,
            monthlyUsd: shop.current_time_period.monthly_usd.to_f,
            currentUsdPaid: shop.current_time_period.usd_paid.to_f,
            totalUsdPaid: shop.total_usd_paid.to_f
          }
        }
        expect(Analytics).to receive(:identify).with(analytic_params)

        service.maybe_reinstall_or_uninstall("enterprise", true)
      end

      it "sends an 'App Uninstalled' analytic" do
        analytic_params = {
          user_id: shop.user.id,
          event: "App Uninstalled",
          properties: {
            email: shop.user.email,
            subscription_length: nil,
            current_days_installed: shop.current_time_period.lapsed_days,
            total_days_installed: shop.total_days_installed,
            current_periods_paid: shop.current_time_period.periods_paid,
            total_periods_paid: shop.total_periods_paid,
            monthly_usd: shop.current_time_period.monthly_usd.to_f,
            current_usd_paid: shop.current_time_period.usd_paid.to_f,
            total_usd_paid: shop.total_usd_paid.to_f
          }
        }

        expect(Analytics).to receive(:track).with(analytic_params)

        service.maybe_reinstall_or_uninstall("enterprise", true)
      end
    end

    context "when neither uninstalling or reinstalling" do
      it "does not send any analytics" do
        expect(Analytics).not_to receive(:track)
        expect(Analytics).not_to receive(:identify)

        service.maybe_reinstall_or_uninstall("enterprise", false)
      end
    end
  end

  describe "#track_shopify_plan_updated" do
    it "sends an identify analytic" do
      expect(Analytics).to receive(:identify).with(
        user_id: shop.user.id,
        traits: {
          shopifyPlan: "enterprise"
        }
      )
      service.track_shopify_plan_updated("enterprise")
    end

    it "sends an track analytic" do
      expect(Analytics).to receive(:track).with(
        user_id: shop.user.id,
        event: "Shopify Plan Updated",
        properties: {
          email: shop.user.email,
          pre_shopify_plan: shop.shopify_plan,
          post_shopify_plan: "enterprise"
        }
      )
      service.track_shopify_plan_updated("enterprise")
    end
  end

  describe "#track_handed_off" do
    it "sends an identify analytic" do
      analytic_params = {
        user_id: shop.user.id,
        traits: {
          shopifyPlan: "enterprise"
        }
      }

      expect(Analytics).to receive(:identify).with(analytic_params)

      service.track_handed_off("enterprise")
    end

    it "sends an 'App Handed Off' track analytic" do
      analytic_params = {
        user_id: shop.user.id,
        event: "Shop Handed Off",
        properties: {
          email: shop.user.email,
          shopify_plan: "enterprise"
        }
      }

      expect(Analytics).to receive(:track).with(analytic_params)

      service.track_handed_off("enterprise")
    end
  end

  describe "#track_cancelled" do
    it "sends an identify analytic" do
      analytic_params = {
        user_id: shop.user.id,
        traits: {
          status: :inactive,
          subscriptionLength: shop.user.subscription_length,
          currentDaysInstalled: shop.current_time_period.lapsed_days,
          totalDaysInstalled: shop.total_days_installed,
          currentPeriodsPaid: shop.current_time_period.periods_paid,
          totalPeriodsPaid: shop.total_periods_paid,
          monthlyUsd: shop.current_time_period.monthly_usd.to_f,
          currentUsdPaid: shop.current_time_period.usd_paid.to_f,
          totalUsdPaid: shop.total_usd_paid.to_f
        }
      }

      expect(Analytics).to receive(:identify).with(analytic_params)

      service.track_cancelled
    end

    it "sends a 'Shop Closed' track analytic" do
      analytic_params = {
        user_id: shop.user.id,
        event: "Shop Closed",
        properties: {
          email: shop.user.email,
          subscription_length: shop.user.subscription_length,
          current_days_installed: shop.current_time_period.lapsed_days,
          total_days_installed: shop.total_days_installed,
          current_periods_paid: shop.current_time_period.periods_paid,
          total_periods_paid: shop.total_periods_paid,
          monthly_usd: shop.current_time_period.monthly_usd.to_f,
          current_usd_paid: shop.current_time_period.usd_paid.to_f,
          total_usd_paid: shop.total_usd_paid.to_f
        }
      }

      expect(Analytics).to receive(:track).with(analytic_params)

      service.track_cancelled
    end
  end

  describe "#track_installed" do
    it "sends an identify analytic" do
      analytic_params = {
        user_id: shop.user.id,
        traits: {
          status: :active,
          shopifyPlan: "affiliate",
          appPlan: "foobar"
        }
      }

      expect(Analytics).to receive(:identify).with(analytic_params)

      service.track_installed
    end

    it "sends an 'App Installed' track analytic" do
      analytic_params = {
        user_id: shop.user.id,
        event: "App Installed",
        properties: {
          "registration method": "shopify",
          email: shop.user.email,
          shopify_plan: "affiliate"
        }
      }

      expect(Analytics).to receive(:track).with(analytic_params)

      service.track_installed
    end
  end
end
