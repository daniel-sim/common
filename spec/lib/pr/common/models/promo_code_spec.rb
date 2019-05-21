require "rails_helper"

describe PR::Common::Models::PromoCode do
  subject(:promo_code) { described_class.new(code: "oneTwoThree") }

  it { is_expected.to have_many :shops }
  it { is_expected.to validate_presence_of :code }
  it { is_expected.to validate_numericality_of(:value).is_greater_than_or_equal_to(0) }
  it { is_expected.to belong_to(:created_by).class_name("PR::Common::Models::Admin") }

  it "upcases the code on save" do
    expect { promo_code.save! }
      .to change(promo_code, :code)
      .from("oneTwoThree")
      .to("ONETWOTHREE")
  end

  it "does not allow non-unique values" do
    promo_code.save!

    duplicate_code = described_class.new(code: promo_code.code)
    duplicate_code.valid?
    expect(duplicate_code.errors.details[:code].first[:error]).to eq :taken
  end

  describe "#redeemable?" do
    subject { promo_code.redeemable? }

    context "when there is no expiry time" do
      it { is_expected.to eq true }
    end

    context "when the expiry time is in the future" do
      around do |example|
        Timecop.freeze do
          promo_code.update!(expires_at: Time.current + 1.second)
          example.run
        end
      end

      it { is_expected.to eq true }
    end

    context "when the expiry time is now" do
      around do |example|
        Timecop.freeze do
          promo_code.update!(expires_at: Time.current)
          example.run
        end
      end

      it { is_expected.to eq false }
    end

    context "when the expiry time is in the past" do
      around do |example|
        Timecop.freeze do
          promo_code.update!(expires_at: Time.current - 1.second)
          example.run
        end
      end

      it { is_expected.to eq false }
    end
  end
end
