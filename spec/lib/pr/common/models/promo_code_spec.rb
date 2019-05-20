require "rails_helper"

describe PR::Common::Models::PromoCode do
  subject(:promo_code) { described_class.new(code: "oneTwoThree") }

  it { is_expected.to have_many :shops }
  it { is_expected.to validate_presence_of :code }
  it { is_expected.to validate_numericality_of(:value).is_greater_than_or_equal_to(0) }

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
end
