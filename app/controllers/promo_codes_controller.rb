class PromoCodesController < ActionController::Base
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
        message: "Success: Promotion applied!"
      }
    end
  end
end
