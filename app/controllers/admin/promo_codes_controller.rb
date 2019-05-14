module Admin
  class PromoCodesController < BaseController
    def new
      @promo_code = PR::Common::Models::PromoCode.new
    end

    def create
      @promo_code = PR::Common::Models::PromoCode.new(promo_code_params)

      if @promo_code.save
        redirect_to new_admin_promo_code_path, notice: "Promo code <code>#{@promo_code.code}</code> saved!"
        return
      end

      flash[:alert] = "Could not save Promo Code."
      render :new
    end

    private

    def promo_code_params
      params.require(:promo_code).permit(:code, :value, :description)
    end
  end
end
