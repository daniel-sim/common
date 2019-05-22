# frozen_string_literal: true

class Admins::SessionsController < Devise::SessionsController
  # Needed because Devise now extends ApplicationController which may include Shopify App gunk
  include PR::Common::SkipShopifyAuthentication
  layout "admin_sessions"

  # before_action :configure_sign_in_params, only: [:create]

  # GET /resource/sign_in
  # def new
  #   super
  # end

  # POST /resource/sign_in
  # def create
  #   super
  # end

  # DELETE /resource/sign_out
  # def destroy
  #   super
  # end

  # protected

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_in_params
  #   devise_parameter_sanitizer.permit(:sign_in, keys: [:attribute])
  # end

  private

  def after_sign_in_path_for(resource)
    new_admin_promo_code_path
  end
end
