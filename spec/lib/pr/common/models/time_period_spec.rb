require "rails_helper"

describe PR::Common::Models::TimePeriod do
  let(:user) { create(:user) }

  it do
    is_expected.to define_enum_for(:kind)
      .with_values %i[installed reinstalled reopened
                      uninstalled closed]
  end

  context "when newly created" do
    let(:time_period) { described_class.create! }

    it "has a non-nil `start_time`" do
      expect(time_period.reload.start_time).not_to be_nil
    end

    it "defaults to an installed kind" do
      expect(time_period).to be_installed
    end
  end

  describe ".not_yet_ended" do
    let(:current_time) { Time.zone.local(2017, 1, 2) }

    around { |example| Timecop.freeze(current_time, &example.method(:run)) }

    it "includes time periods that have an end time not set" do
      time_period = create(:time_period)

      expect(described_class.not_yet_ended.pluck(:id)).to include(time_period.id)
    end

    it "includes time periods that have an end time in the future" do
      time_period = create(:time_period, end_time: Time.zone.local(2017, 1, 3))

      expect(described_class.not_yet_ended.pluck(:id)).to include(time_period.id)
    end

    it "does not include periods that have an end time in the past" do
      time_period = create(:time_period, end_time: Time.zone.local(2017, 1, 1))

      expect(described_class.not_yet_ended.pluck(:id)).not_to include(time_period.id)
    end

    it "does not include periods that have an end time of now" do
      time_period = create(:time_period, end_time: current_time)

      expect(described_class.not_yet_ended.pluck(:id)).not_to include(time_period.id)
    end
  end

  describe ".whilst_in_use" do
    it "includes installed time period" do
      time_period = create(:time_period, :installed)

      expect(described_class.whilst_in_use.pluck(:id)).to include(time_period.id)
    end

    it "includes reinstalled time period" do
      time_period = create(:time_period, :reinstalled)

      expect(described_class.whilst_in_use.pluck(:id)).to include(time_period.id)
    end

    it "includes reopened time period" do
      time_period = create(:time_period, :reopened)

      expect(described_class.whilst_in_use.pluck(:id)).to include(time_period.id)
    end

    it "does not include uninstalled time period" do
      time_period = create(:time_period, :uninstalled)

      expect(described_class.whilst_in_use.pluck(:id)).not_to include(time_period.id)
    end

    it "does not include closed time period" do
      time_period = create(:time_period, :closed)

      expect(described_class.whilst_in_use.pluck(:id)).not_to include(time_period.id)
    end
  end

  describe "#lapsed_days" do
    subject(:time_period) { described_class.new(start_time: start_time, end_time: end_time) }

    let(:current_time) { Time.zone.local(2018, 1, 10, 0, 0, 1) }
    let(:end_time) { nil }

    around { |example| Timecop.freeze(current_time, &example.method(:run)) }

    context "with no end time" do
      context "when time period started just now" do
        let(:start_time) { current_time }

        it "returns 0" do
          expect(time_period.lapsed_days).to eq 0
        end
      end

      context "when time period started 1 second ago" do
        let(:start_time) { current_time - 1.second }

        it "rounds up to 1" do
          expect(time_period.lapsed_days).to eq 1
        end
      end

      context "when time period started exactly 1 day ago" do
        let(:start_time) { current_time - 1.day }

        it "returns 1" do
          expect(time_period.lapsed_days).to eq 1
        end
      end

      context "when time period started just over 10 days ago" do
        let(:start_time) { Time.zone.local(2018, 1, 1) }

        it "returns 10" do
          expect(time_period.lapsed_days).to eq 10
        end
      end
    end

    context "with an end time" do
      let(:start_time) { Time.zone.local(2018, 1, 1) }
      let(:end_time) { Time.zone.local(2018, 1, 5, 0, 0, 1) }

      it "ignores the current time and returns the lapsed days between start to end time" do
        expect(time_period.lapsed_days).to eq 5
      end
    end
  end

  describe "#lapsed_days_since_last_shop_retained_analytic" do
    let(:current_time) { Time.zone.local(2018, 1, 10, 0, 0, 1) }

    around { |example| Timecop.freeze(current_time, &example.method(:run)) }

    context "when shop_retained_analytic_sent_at is nil" do
      subject(:time_period) do
        described_class.new(start_time: Time.zone.local(2018, 1, 1),
                            shop_retained_analytic_sent_at: nil)
      end

      it "is calculated from the `start_time`" do
        expect(time_period.lapsed_days_since_last_shop_retained_analytic).to eq 10
      end
    end

    context "when shop_retained_analytic_sent_at is set" do
      subject(:time_period) do
        described_class.new(start_time: Time.zone.local(2018, 1, 1),
                            shop_retained_analytic_sent_at: Time.zone.local(2018, 1, 6))
      end

      it "is calculated from the `last_shop_retained_analytic_at`" do
        expect(time_period.lapsed_days_since_last_shop_retained_analytic).to eq 5
      end
    end
  end

  describe "#in_use?" do
    %i[installed reinstalled reopened].each do |kind|
      context "when time period is #{kind}" do
        subject(:time_period) { build(:time_period, kind) }

        it "returns true" do
          expect(time_period).to be_in_use
        end
      end
    end

    %i[uninstalled closed].each do |kind|
      context "when time period is #{kind}" do
        subject(:time_period) { build(:time_period, kind) }

        it "returns false" do
          expect(time_period).not_to be_in_use
        end
      end
    end
  end

  describe "#converted_to_paid?" do
    context "when converted_to_paid_at is set" do
      subject(:time_period) { build(:time_period, converted_to_paid_at: Time.current) }

      it "returns true" do
        expect(time_period).to be_converted_to_paid
      end
    end

    context "when converted_to_paid_at is not set" do
      subject(:time_period) { build(:time_period) }

      it "returns false" do
        expect(time_period).not_to be_converted_to_paid
      end
    end
  end

  describe "#ended?" do
    context "when end_time is set" do
      subject(:time_period) { build(:time_period, end_time: Time.current) }

      it "returns true" do
        expect(time_period).to be_ended
      end
    end

    context "when end_time is not set" do
      subject(:time_period) { build(:time_period) }

      it "returns false" do
        expect(time_period).not_to be_ended
      end
    end
  end

  describe "#paid_now" do
    subject(:time_period) { build(:time_period) }

    let(:current_time) { Time.zone.local(2017, 1, 2) }

    around { |example| Timecop.freeze(current_time, &example.method(:run)) }

    context "when passed a time" do
      let(:time) { Time.zone.local(2017, 1, 1) }

      it "sets period_last_paid_at to the current time" do

        expect { time_period.paid_now(time) }
          .to change(time_period, :period_last_paid_at)
          .from(nil)
          .to(time)
      end

      it "increments periods_paid" do
        expect { time_period.paid_now(time) }
          .to change(time_period, :periods_paid)
          .from(0)
          .to(1)
      end
    end

    context "when not passed a time" do
      it "sets period_last_paid_at to the current time" do
        expect { time_period.paid_now }
          .to change(time_period, :period_last_paid_at)
          .from(nil)
          .to(Time.current)
      end

      it "increments periods_paid" do
        expect { time_period.paid_now }
          .to change(time_period, :periods_paid)
          .from(0)
          .to(1)
      end
    end
  end

  describe "#paid_now!" do
    subject(:time_period) { create(:time_period) }

    let(:current_time) { Time.zone.local(2017, 1, 2) }

    around { |example| Timecop.freeze(current_time, &example.method(:run)) }

    context "when passed a time" do
      let(:time) { Time.zone.local(2017, 1, 1) }

      it "persists period_last_paid_at to passed" do
        expect { time_period.paid_now!(time) }
          .to change { time_period.reload.period_last_paid_at }
          .from(nil)
          .to(time)
      end

      it "increments periods_paid" do
        expect { time_period.paid_now!(time) }
          .to change { time_period.reload.periods_paid }
          .from(0)
          .to(1)
      end
    end

    context "when not passed a time" do
      it "sets period_last_paid_at to the current time" do
        expect { time_period.paid_now! }
          .to change { time_period.reload.period_last_paid_at }
          .from(nil)
          .to(Time.current)
      end

      it "increments periods_paid" do
        expect { time_period.paid_now! }
          .to change { time_period.reload.periods_paid }
          .from(0)
          .to(1)
      end
    end
  end

  describe "#usd_paid" do
    subject(:time_period) { build(:time_period, monthly_usd: 3.50) }

    context "when no periods were paid" do
      it "returns 0" do
        expect(time_period.usd_paid).to eq 0
      end
    end

    context "when periods were paid" do
      before { time_period.periods_paid = 5 }

      it "returns the number of payments multiplied by the monthly cost" do
        expect(time_period.usd_paid).to eq 17.50
      end
    end
  end
end
