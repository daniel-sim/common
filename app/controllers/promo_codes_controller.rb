class PromoCodesController < ApplicationController
  STATUS_VALID = "valid".freeze
  STATUS_ERROR = "error".freeze

  def check
    service = ParamsPromoCodeService.new(params)

    render json: response_json(service)
  end

  private

  def response_json(service)
    if service.error
      { status: STATUS_ERROR, message: service.error }
    else
      {
        status: STATUS_VALID,
        message: "Promo code applied: you pay #{service.record.value}% of the normal price."
      }
    end
  end
end
