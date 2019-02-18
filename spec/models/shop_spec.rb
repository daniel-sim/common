require "rails_helper"

RSpec.describe Shop, type: :model do
  describe ".with_active_charge" do
    it "includes only shops with a user whose active charge is true" do
      active_charge_shop = create(:shop, user: build(:user, active_charge: true))
      inactive_charge_shop = create(:shop)

      shops = Shop.with_active_charge
      expect(shops).to include(active_charge_shop)
      expect(shops).not_to include(inactive_charge_shop)
    end
  end

  describe ".with_active_plan" do
    it "includes only shops whose plan is not cancelled, frozen, locked, or fraudulent" do
      active_plan_shop = create(:shop)
      cancelled_plan_shop = create(:shop, shopify_plan: "cancelled")
      locked_plan_shop = create(:shop, shopify_plan: "locked")
      frozen_plan_shop = create(:shop, shopify_plan: "frozen")
      fraudulent_plan_shop = create(:shop, shopify_plan: "frozen")

      shops = Shop.with_active_plan
      expect(shops).to include active_plan_shop
      expect(shops).not_to include cancelled_plan_shop
      expect(shops).not_to include locked_plan_shop
      expect(shops).not_to include fraudulent_plan_shop
      expect(shops).not_to include frozen_plan_shop
    end
  end

  describe ".installed" do
    it "includes only shops which are not uninstalled" do
      installed_shop = create(:shop, uninstalled: false)
      uninstalled_shop = create(:shop, uninstalled: true)

      shops = Shop.installed
      expect(shops).to include installed_shop
      expect(shops).not_to include uninstalled_shop
    end
  end

  describe "#app_plan" do
    context "when it is not set to anything" do
      it "returns nil" do
        expect(build(:shop).app_plan).to be_nil
      end
    end

    context "when it is not set to anything but a default is set" do
      before { allow(PR::Common.config).to receive(:default_app_plan).and_return("something") }

      it "returns the default" do
        expect(build(:shop).app_plan).to eq "something"
      end
    end

    context "when it is set" do
      it "returns the set app_plan" do
        expect(build(:shop, app_plan: "foo").app_plan).to eq "foo"
      end
    end
  end

  describe "#status" do
    it "is :inactive when shop is frozen" do
      expect(build(:shop, shopify_plan: Shop::PLAN_FROZEN).status).to eq :inactive
    end

    it "is :inactive when shop is closed" do
      expect(build(:shop, shopify_plan: Shop::PLAN_CANCELLED).status).to eq :inactive
    end

    it "is :inactive when shop is fraudulent" do
      expect(build(:shop, shopify_plan: Shop::PLAN_FRAUDULENT).status).to eq :inactive
    end

    it "is :locked when shop is locked" do
      expect(build(:shop, shopify_plan: Shop::PLAN_LOCKED).status).to eq :locked
    end

    it "is :uninstalled if app is uninstalled" do
      expect(build(:shop, uninstalled: true).status).to eq :uninstalled
    end

    it "is :active for any other shop" do
      expect(build(:shop).status).to eq :active
    end
  end

  describe "#time_periods" do
    let(:current_time) { DateTime.new(2018, 1, 1) }
    around { |example| Timecop.freeze(current_time, &(example.method(:run))) }

    context "when shop is newly installed" do
      let(:shop) { create(:shop) }

      it "creates a new time period of type `installed`" do
        expect(shop.time_periods.count).to eq 1
        expect(shop.time_periods.last).to be_installed
        expect(shop.time_periods.last.start_time).to eq current_time
        expect(shop.time_periods.last.end_time).to be_nil
      end
    end

    context "when shop is `uninstalled`" do
      let(:shop) { create(:shop, :uninstalled) }

      it "creates a new time period of type `uninstalled`" do
        expect(shop.time_periods.count).to eq 1
        expect(shop.time_periods.last).to be_uninstalled
        expect(shop.time_periods.last.start_time).to eq current_time
        expect(shop.time_periods.last.end_time).to be_nil
      end
    end

    context "when shop has a `cancelled` plan" do
      let(:shop) { create(:shop, :cancelled) }

      it "creates a new time period of type `closed`" do
        expect(shop.time_periods.count).to eq 1
        expect(shop.time_periods.last).to be_closed
        expect(shop.time_periods.last.start_time).to eq current_time
        expect(shop.time_periods.last.end_time).to be_nil
      end
    end

    shared_examples "inherits attributes from previous time period" do
      it "copies converted_to_paid_at, monthly_usd, and period_last_paid_at from the previous time period" do
        converted_to_paid_at = Time.zone.local(2018, 1, 1)
        period_last_paid_at = Time.zone.local(2018, 1, 1)
        monthly_usd = 20.0

        shop.current_time_period.update!(monthly_usd: monthly_usd,
                                         period_last_paid_at: period_last_paid_at,
                                         converted_to_paid_at: converted_to_paid_at)

        operation

        expect(shop.time_periods.last.monthly_usd).to eq monthly_usd
        expect(shop.time_periods.last.period_last_paid_at).to eq period_last_paid_at
        expect(shop.time_periods.last.converted_to_paid_at).to eq converted_to_paid_at
      end
    end

    context "when transitioning from installed to uninstalled" do
      let!(:shop) { create(:shop) }
      let(:operation) { shop.update!(uninstalled: true) }

      it "ends the current period" do
        operation

        expect(shop.time_periods.first.end_time).to eq current_time
      end

      it "creates a new time period" do
        expect { operation }
          .to change { shop.time_periods.count }
          .from(1)
          .to(2)
      end

      it "starts now" do
        operation

        expect(shop.time_periods.last.start_time).to eq current_time
      end

      it "has no end time" do
        operation

        expect(shop.time_periods.last.end_time).to eq nil
      end

      it "is of kind 'uninstalled'" do
        operation

        expect(shop.time_periods.last).to be_uninstalled
      end

      include_examples "inherits attributes from previous time period"
    end

    context "when transitioning from uninstalled to reinstalled" do
      let!(:shop) { create(:shop, :uninstalled) }
      let(:operation) { shop.update!(uninstalled: false) }

      it "ends the current period" do
        operation

        expect(shop.time_periods.first.end_time).to eq current_time
      end

      it "creates a new time period" do
        expect { operation }
          .to change { shop.time_periods.count }
          .from(1)
          .to(2)
      end

      it "starts now" do
        operation

        expect(shop.time_periods.last.start_time).to eq current_time
      end

      it "has no end time" do
        operation

        expect(shop.time_periods.last.end_time).to eq nil
      end

      it "is of kind 'reinstalled'" do
        operation

        expect(shop.time_periods.last).to be_reinstalled
      end

      it "does not copy over converted_to_paid_at, monthly_usd, and period_last_paid_at from the previous time period" do
        converted_to_paid_at = Time.zone.local(2018, 1, 1)
        period_last_paid_at = Time.zone.local(2018, 1, 1)
        monthly_usd = 20.0

        shop.current_time_period.update!(monthly_usd: monthly_usd,
                                         period_last_paid_at: period_last_paid_at,
                                         converted_to_paid_at: converted_to_paid_at)

        operation

        expect(shop.time_periods.last.monthly_usd).to eq 0
        expect(shop.time_periods.last.period_last_paid_at).to eq nil
        expect(shop.time_periods.last.converted_to_paid_at).to eq nil
      end
    end

    context "when transitioning from installed to closed" do
      let!(:shop) { create(:shop) }
      let(:operation) { shop.update!(shopify_plan: "cancelled") }

      it "ends the current period" do
        operation

        expect(shop.time_periods.first.end_time).to eq current_time
      end

      it "creates a new time period" do
        expect { operation }
          .to change { shop.time_periods.count }
          .from(1)
          .to(2)
      end

      it "starts now" do
        operation

        expect(shop.time_periods.last.start_time).to eq current_time
      end

      it "has no end time" do
        operation

        expect(shop.time_periods.last.end_time).to eq nil
      end

      it "is of kind 'closed'" do
        operation

        expect(shop.time_periods.last).to be_closed
      end

      include_examples "inherits attributes from previous time period"
    end

    context "when transitioning from closed to reopened" do
      let!(:shop) { create(:shop, :cancelled) }
      let(:operation) { shop.update!(shopify_plan: "affiliate") }

      it "ends the current period" do
        operation

        expect(shop.time_periods.first.end_time).to eq current_time
      end

      it "creates a new time period" do
        expect { operation }
          .to change { shop.time_periods.count }
          .from(1)
          .to(2)
      end

      it "starts now" do
        operation

        expect(shop.time_periods.last.start_time).to eq current_time
      end

      it "has no end time" do
        operation

        expect(shop.time_periods.last.end_time).to eq nil
      end

      it "is of kind 'reopened'" do
        operation

        expect(shop.time_periods.last).to be_reopened
      end

      include_examples "inherits attributes from previous time period"
    end
  end

  describe "#current_time_period" do
    let(:shop) { create(:shop) }

    before do
      # installed -> uninstalled -> reinstalled -> closed -> reopened
      shop.update!(uninstalled: true)
      shop.update!(uninstalled: "false")
      shop.update!(shopify_plan: "cancelled")
      shop.update!(shopify_plan: "basic")
    end

    it "returns the most recent time period" do
      expect(shop.current_time_period).to be_reopened
    end
  end

  describe "#total_days_installed" do
    it "returns the total days whilst installed, reopened, and reinstalled" do
      # new shop with installed time period
      Timecop.freeze Time.zone.local(2018, 1, 1)
      shop = create(:shop)

      # 1 day effective, create uninstalled time period
      Timecop.freeze Time.zone.local(2018, 1, 1, 0, 0, 1)
      shop.update!(uninstalled: true)

      # 1 day effective, create reinstalled time period
      Timecop.freeze Time.zone.local(2018, 1, 1, 0, 0, 2)
      shop.update!(uninstalled: "false")

      # 1 day effective, create cancelled time period
      Timecop.freeze Time.zone.local(2018, 1, 1, 0, 0, 3)

      shop.update!(shopify_plan: "cancelled")

      # 1 day effective, create reopened time period
      Timecop.freeze Time.zone.local(2018, 1, 1, 0, 0, 4)
      shop.update!(shopify_plan: "basic")

      # 1 day effective
      Timecop.freeze Time.zone.local(2018, 1, 1, 0, 0, 5)

      expect(shop.total_days_installed).to eq 3

      Timecop.return
    end
  end

  # installed -> uninstalled -> reinstalled
  # total periods paid: 7, 3 of which are at $100 and 4 of which are at $10
  def create_paid_time_periods(shop)
    shop.current_time_period.update!(periods_paid: 3, monthly_usd: 100.0)
    shop.update!(uninstalled: true)
    shop.update!(uninstalled: "false")
    shop.current_time_period.update!(periods_paid: 4, monthly_usd: 10.0)
  end

  describe "#total_periods_paid" do
    subject(:shop) { create(:shop) }

    before do
      create_paid_time_periods(shop)
      shop.reload
    end

    it "returns the periods paid across all time periods" do
      expect(shop.total_periods_paid).to eq 7
    end
  end

  describe "#total_usd_paid" do
    subject(:shop) { create(:shop) }

    before do
      create_paid_time_periods(shop)
      shop.reload
    end

    it "returns the amount paid across all time periods" do
      expect(shop.total_usd_paid).to eq BigDecimal("340.0")
    end
  end
end
