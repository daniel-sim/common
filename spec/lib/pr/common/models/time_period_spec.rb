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
