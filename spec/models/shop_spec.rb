require 'rails_helper'

RSpec.describe Shop, type: :model do
  describe '.with_active_charge' do
    it 'includes only shops with a user whose active charge is true' do
      active_charge_shop = create(:shop, user: build(:user, active_charge: true))
      inactive_charge_shop = create(:shop)

      shops = Shop.with_active_charge
      expect(shops).to include(active_charge_shop)
      expect(shops).not_to include(inactive_charge_shop)
    end
  end

  describe '.with_active_plan' do
    it 'includes only shops whose plan is not cancelled, frozen, 🌲, or locked' do
      active_plan_shop = create(:shop)
      cancelled_plan_shop = create(:shop, plan_name: 'cancelled')
      locked_plan_shop = create(:shop, plan_name: 'locked')
      tree_plan_shop = create(:shop, plan_name: '🌲')
      frozen_plan_shop = create(:shop, plan_name: 'frozen')

      shops = Shop.with_active_plan
      expect(shops).to include active_plan_shop
      expect(shops).not_to include cancelled_plan_shop
      expect(shops).not_to include locked_plan_shop
      expect(shops).not_to include tree_plan_shop
      expect(shops).not_to include frozen_plan_shop
    end
  end

  describe '.installed' do
    it 'includes only shops which are not uninstalled' do
      installed_shop = create(:shop, uninstalled: false)
      uninstalled_shop = create(:shop, uninstalled: true)

      shops = Shop.installed
      expect(shops).to include installed_shop
      expect(shops).not_to include uninstalled_shop
    end
  end

  describe "App gets reinstalled" do
    context "when shop is reinstalled" do
      let(:shop) { create(:shop, :uninstalled, user: build(:user, charged_at: Time.current)) }

      it "sets reinstalled_at to the current time" do
        time = Time.current

        Timecop.freeze(time)
        expect { shop.update!(uninstalled: false) }
          .to change { shop.reinstalled_at }
          .from(nil)
          .to(time)
      end

      it "clears charged_at" do
        expect { shop.update!(uninstalled: false) }
          .to change { shop.charged_at }
          .to(nil)
      end
    end
  end

  describe "Shop gets reopened" do
    context "when shop is reopened from cancelled" do
      let(:shop) { create(:shop, :cancelled, user: build(:user, charged_at: Time.current)) }

      it "is set to the current time" do
        time = Time.current

        Timecop.freeze(time)
        expect { shop.update!(plan_name: "basic") }
          .to change { shop.reopened_at }
          .from(nil)
          .to(time)
      end

      it "clears charged_at" do
        expect { shop.update!(plan_name: "basic") }
          .to change { shop.charged_at }
          .to(nil)
      end
    end

    context "when shop is reopened from frozen" do
      let(:shop) { create(:shop, :frozen, user: build(:user, charged_at: Time.current)) }

      it "is set to the current time" do
        time = Time.current

        Timecop.freeze(time)
        expect { shop.update!(plan_name: "basic") }
          .to change { shop.reopened_at }
          .from(nil)
          .to(time)
      end

      it "clears charged_at" do
        expect { shop.update!(plan_name: "basic") }
          .to change { shop.charged_at }
          .to(nil)
      end
    end
  end

  describe "Shop gets frozen" do
    context "when shop goes from cancelled to frozen" do
      let(:shop) { create(:shop, :cancelled) }

      it "does not change reopened_at" do
        expect { shop.update!(plan_name: "frozen") }
          .not_to change { shop.reopened_at }
      end
    end
  end

  describe "Shop gets closed" do
    context "when shop goes from frozen to cancelled" do
      let(:shop) { create(:shop, :frozen) }

      it "does not change reopened_at" do
        expect { shop.update!(plan_name: "cancelled") }
          .not_to change { shop.reopened_at }
      end
    end
  end
end
