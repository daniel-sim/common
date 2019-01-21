class ChargesController < ApplicationController
  include ShopifyApp::LoginProtection

  before_action :login_again_if_different_shop
  around_action :shopify_session
  before_action :load_user

  def create
    price = charge_service.up_to_date_price[:price]
    charge = charge_service.create_charge(price, request.base_url)

    # price is free
    return redirect_to charge_success_path if price.zero?
    return fullpage_redirect_to(charge.confirmation_url) if charge

    # charge failed
    redirect_to charge_failed_path
  end

  def callback
    @charge = ShopifyAPI::RecurringApplicationCharge.find(params[:charge_id])

    case @charge.status
    when "accepted"
      charge_service.activate_charge(@charge)
      return redirect_to charge_success_path
    when "declined"
      return redirect_to charge_declined_path
    end

    redirect_to charge_failed_path
  end

  private

  def charge_service
    @charge_service ||= PR::Common::ChargeService.new(@user.shop)
  end

  def charge_success_path
    "#{Settings.client_url}/charge/succeed"
  end

  def charge_declined_path
    "#{Settings.client_url}/charge/declined"
  end

  def charge_failed_path
    "#{Settings.client_url}/charge/failed"
  end

  def load_user
    @user = User.find_by!(access_token: params[:access_token])
  end
end
