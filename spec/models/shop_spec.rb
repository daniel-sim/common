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
    it "includes only shops whose plan is not cancelled, frozen, 🌲, or locked" do
      active_plan_shop = create(:shop)
      cancelled_plan_shop = create(:shop, shopify_plan: "cancelled")
      locked_plan_shop = create(:shop, shopify_plan: "locked")
      tree_plan_shop = create(:shop, shopify_plan: "🌲")
      frozen_plan_shop = create(:shop, shopify_plan: "frozen")

      shops = Shop.with_active_plan
      expect(shops).to include active_plan_shop
      expect(shops).not_to include cancelled_plan_shop
      expect(shops).not_to include locked_plan_shop
      expect(shops).not_to include tree_plan_shop
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

    before { create_paid_time_periods(shop) }

    it "returns the periods paid across all time periods" do
      expect(shop.total_periods_paid).to eq 7
    end
  end

  describe "#total_usd_paid" do
    subject(:shop) { create(:shop) }

    before { create_paid_time_periods(shop) }

    it "returns the amount paid across all time periods" do
      expect(shop.total_usd_paid).to eq BigDecimal("340.0")
    end
  end
end
