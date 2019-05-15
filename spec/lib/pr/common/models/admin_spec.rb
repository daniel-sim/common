require "rails_helper"

describe PR::Common::Models::Admin do
  it { is_expected.to have_many(:promo_codes).with_foreign_key(:created_by_id) }
end
