ShopifyApp.configure do |config|
  # For non-common, application specific webhooks be sure to do config.webhooks.push() rather than overwriting those here
  # TODO: Check and document what happens when adding/removing webhooks from here for existing shops?
  # https://pluginseo.ngrok.io
  config.webhook_jobs_namespace = "shopify/webhooks"
  config.webhooks = [
      {
        topic: "app/uninstalled",
        address: "#{Settings.webhook_url}/webhooks/app_uninstalled",
        format: 'json'
      },
      { topic: "shop/update",
        address: "#{Settings.webhook_url}/webhooks/shop_update",
        format: 'json'
      },
  ]
  config.api_version = "2019-04"
  config.after_authenticate_job = { job: Shopify::AfterAuthenticateJob, inline: true }
end
