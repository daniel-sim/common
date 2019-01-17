require "rails_helper"

describe PR::Common::Models::TimePeriod do
  let(:user) { create(:user) }

  it do
    is_expected.to define_enum_for(:kind)
      .with_values %i[installed
                      reinstalled
                      reopened
                      uninstalled
                      closed]
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
end
