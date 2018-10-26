class ChargesController < ApplicationController
  include ShopifyApp::LoginProtection

  before_action :login_again_if_different_shop
  around_action :shopify_session
  before_action :find_user, :load_charge

  def create
    @recurring_application_charge.try!(:cancel)

    params = charge_params(@user.access_token)

    if (params[:price] > 0)
      @charge = ShopifyAPI::RecurringApplicationCharge.new(params)
      if @charge.save
        fullpage_redirect_to @charge.confirmation_url
      else
        redirect_to "#{Settings.client_url}/charge/failed"
      end
    else
      activate_user_without_charge
      redirect_to "#{Settings.client_url}/charge/succeed"
    end
  end

  def callback
    @charge = ShopifyAPI::RecurringApplicationCharge.find(params[:charge_id])

    if @charge.status == 'accepted'
      activate_user
      redirect_to "#{Settings.client_url}/charge/succeed"
    elsif @charge.status == 'declined'
      redirect_to "#{Settings.client_url}/charge/declined"
    else
      redirect_to "#{Settings.client_url}/charge/failed"
    end
  end

  private

  def activate_user_without_charge
    @user.update(active_charge: true, charged_at: DateTime.now)

    Analytics.track({
      user_id: @user.id,
      event: "No Charge Activated",
      properties: {
        "email": @user.email
      },
    })
  end

  def activate_user
    @charge.activate
    @user.update(active_charge: true, charged_at: DateTime.now)
    Analytics.track({
      user_id: @user.id,
      event: 'Charge Activated',
      properties: {
        'monthly_usd': @charge.price,
        'email': @user.email
      },
    })
  end

  def find_user
    @user = User.find_by!(access_token: params[:access_token])
  end

  def load_charge
    @charge = ShopifyAPI::RecurringApplicationCharge.current
  end

  def charge_params(access_token)
    api_shop = ShopifyAPI::Shop.current
    our_shop = Shop.find_by!(shopify_domain: api_shop.myshopify_domain)

    plan_name = api_shop.plan_name

    shopify_service = PR::Common::ShopifyService.new(shop: our_shop)
    best_price = shopify_service.determine_price(plan_name: plan_name)

    best_price[:test] = !Rails.env.production?
    best_price[:return_url] = "#{request.base_url}#{callback_charges_path}?access_token=#{access_token}"

    return best_price
  end
end
