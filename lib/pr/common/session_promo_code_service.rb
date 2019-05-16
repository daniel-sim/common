class SessionPromoCodeService
  KEY = :promo_code

  def initialize(session)
    @session = session
  end

  def maybe_apply_to_shop(shop)
    return unless redeemable?

    PR::Common::Models::PromoCode.transaction do
      return unless redeemable? # check again now that we've locked the table

      Rails.logger.info("Applying promo code. code=#{code}, shop=#{shop.shopify_domain}")

      shop.update!(promo_code: record)
    end
  end

  def store(promo_code)
    @session[KEY] = promo_code.code
  end

  def clear
    @session.delete(KEY)
  end

  private

  def redeemable?
    record&.redeemable?
  end

  def record
    @record ||= PR::Common::Models::PromoCode.find_by(code: code)
  end

  def code
    @session[KEY]
  end
end
