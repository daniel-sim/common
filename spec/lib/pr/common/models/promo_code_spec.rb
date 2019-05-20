require "rails_helper"

describe PR::Common::Models::PromoCode do
  subject(:promo_code) { described_class.new(code: "oneTwoThree") }

  it { is_expected.to have_many :shops }
  it { is_expected.to validate_presence_of :code }
  it { is_expected.to validate_uniqueness_of :code }

  it "upcases the code on save" do
    expect { promo_code.save! }
      .to change(promo_code, :code)
      .from("oneTwoThree")
      .to("ONETWOTHREE")
  end
end
