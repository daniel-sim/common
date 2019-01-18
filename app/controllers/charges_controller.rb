class ChargesController < ApplicationController
  include ShopifyApp::LoginProtection

  before_action :login_again_if_different_shop
  around_action :shopify_session

  def create
    price = params[:price]

    raise "Price is < 0: #{price}" if price.negative?

    charge = ChargeService.new(@shop).create_charge(price)

    return redirect_to(charge_success_path) if price.zero?
    return fullpage_redirect_to(charge.confirmation_url) if charge_created

    redirect_to charge_failed_path
  end

  def callback
    @charge = ShopifyAPI::RecurringApplicationCharge.find(params[:charge_id])

    case @charge.status
    when "accepted"
      ChargeService.new(@shop).activate_charge(charge)
      return redirect_to charge_success_path
    when "declined"
      return redirect_to charge_declined_path
    end

    redirect_to charge_failed_path
  end

  private

  def charge_success_path
    "#{Settings.client_url}/charge/succeed"
  end

  def charge_declined_path
    "#{Settings.client_url}/charge/declined"
  end

  def charge_failed_path
    "#{Settings.client_url}/charge/failed"
  end
end
