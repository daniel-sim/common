require 'rails_helper'

RSpec.describe 'Shop', type: :request do
  describe 'POST shops/callback' do
    let!(:shop) { create(:shop, shopify_plan: 'trial', shopify_domain: 'pluginbackup-dev.myshopify.com') }

    let(:url) { '/shops/callback' }
    let(:params) do
      { 'id' => 2_896_429_168, 'name' => 'pluginbackup-dev', 'email' => 'test@test.com', 'domain' => 'pluginbackup-dev.myshopify.com', 'province' => 'Sao Paulo',
        'country' => 'BR', 'address1' => 'Address', 'zip' => '00000', 'city' => 'São Paulo', 'source' => nil, 'phone' => '555555', 'latitude' => nil, 'longitude' => nil,
        'primary_locale' => 'en', 'address2' => '', 'created_at' => '2018-08-27T10:37:51-03:00', 'updated_at' => '2018-08-27T10:42:15-03:00', 'country_code' => 'BR',
        'country_name' => 'Brazil', 'currency' => 'BRL', 'customer_email' => 'test@test.com', 'timezone' => '(GMT-03:00) America/Sao_Paulo', 'iana_timezone' => 'America/Sao_Paulo',
        'shop_owner' => 'pluginbackup-dev Admin', 'money_format' => 'R$ {{amount_with_comma_separator}}', 'money_with_currency_format' => 'R$ {{amount_with_comma_separator}} BRL',
        'weight_unit' => 'kg', 'province_code' => 'SP', 'taxes_included' => false, 'tax_shipping' => nil, 'county_taxes' => true, 'plan_display_name' => 'affiliate', 'plan_name' => 'affiliate',
        'has_discounts' => false, 'has_gift_cards' => false, 'myshopify_domain' => 'pluginbackup-dev.myshopify.com', 'google_apps_domain' => nil, 'google_apps_login_enabled' => nil,
        'money_in_emails_format' => 'R$ {{amount_with_comma_separator}}', 'money_with_currency_in_emails_format' => 'R$ {{amount_with_comma_separator}} BRL', 'eligible_for_payments' => false,
        'requires_extra_payments_agreement' => false, 'password_enabled' => true, 'has_storefront' => true, 'eligible_for_card_reader_giveaway' => false, 'finances' => true,
        'primary_location_id' => 6_980_862_064, 'checkout_api_supported' => false, 'multi_location_enabled' => false, 'setup_required' => false, 'force_ssl' => true, 'pre_launch_enabled' => false,
        'controller' => 'shops', 'action' => 'callback', 'shop' => { 'id' => 2_896_429_168, 'created_at' => '2018-08-27T10:37:51-03:00', 'updated_at' => '2018-08-27T10:42:15-03:00' } }
    end

    it 'updates user plan name' do
      post url, params: params
      expect(shop.reload.shopify_plan).to eql 'affiliate'
    end
  end
end
