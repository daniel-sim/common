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
end
