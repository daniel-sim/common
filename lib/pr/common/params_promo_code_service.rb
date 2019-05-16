class ParamsPromoCodeService
  KEY = :promo_code

  def initialize(params)
    @params = params
  end

  def record
    @record ||= PR::Common::Models::PromoCode.find_by(code: code)
  end

  def error
    return "Invalid promo code." unless record

    "Promo code expired." unless record.redeemable?
  end

  def code
    @params[KEY]
  end

  def present?
    record.present?
  end
end
