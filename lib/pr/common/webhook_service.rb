module PR
  module Common
    class WebhookService
      # Recreates all webhooks and returns a list of any that failed
      def self.recreate_webhooks!(shops = Shop.installed)
        shops.find_each.map do |shop|
          new(shop).recreate_webhooks! || shop.shopify_domain
        end.reject { |item| item == true }
      end

      def initialize(shop)
        @shop = shop
      end

      def recreate_webhooks!
        wrap_errors do
          with_shop do
            Rails.logger.info "Recreating webhooks for #{@shop.shopify_domain}"

            # If anything fails due to shop not being installed,
            # I would expect it to happen here.
            existing_webhooks = fetch_existing

            # ensure that any new webhooks are installed first.
            # that way, if something goes wrong, at least we haven't removed
            # anything.
            maybe_install_from_config(existing_webhooks)

            maybe_destroy(existing_webhooks)

            true
          end
        end
      end

      private

      def fetch_existing
        ShopifyAPI::Webhook.all
      end

      def maybe_install_from_config(api_webhooks)
        configured_webhooks
          .reject { |configured_webhook| api_webhook_exists?(configured_webhook, api_webhooks) }
          .each(&(ShopifyAPI::Webhook.method(:create)))
      end

      def maybe_destroy(api_webhooks)
        Array.wrap(api_webhooks)
          .reject(&method(:configured_webhook_exists?))
          .each { |api_webhook| ShopifyAPI::Webhook.delete(api_webhook.id) }
      end

      def api_webhook_exists?(configured_webhook, api_webhooks)
        api_webhooks.detect do |api_webhook|
          configured_webhook[:topic] == api_webhook.topic &&
            configured_webhook[:address] == api_webhook.address &&
            configured_webhook[:format] == api_webhook.format
        end
      end

      def configured_webhook_exists?(api_webhook)
        configured_webhooks.include?(
          topic: api_webhook.topic,
          address: api_webhook.address,
          format: api_webhook.format
        )
      end

      def with_shop
        ShopifyAPI::Session.temp(domain: @shop.shopify_domain,
                                 token: @shop.shopify_token,
                                 api_version: @shop.api_version) do
          return yield
        end
      end

      def configured_webhooks
        ShopifyApp.configuration.webhooks
      end

      # We don't want things to explode if something goes wrong, but we do want to
      # notify.
      def wrap_errors
        yield
      rescue ActiveResource::UnauthorizedAccess => e
        # This probably means the shop is no longer installed.
        Rails.logger.error "Failed to modify webhooks for #{@shop.shopify_domain}. "\
          "Unauthorized: Consider checking if it's still installed, and uninstalling if not. Error: "\
          "#{e.message}"

        return false
      rescue ActiveResource::ConnectionError => e
        Rails.logger.error "Failed to modify webhooks for #{@shop.shopify_domain}. "\
          "Some kind of connection error occurred. Error: "\
          "#{e.message}"

        return false
      rescue Timeout::Error => e
        Rails.logger.error "Failed to modify webhooks for #{@shop.shopify_domain}. "\
          "Connection timed out. Error: #{e.message}"

        return false
      rescue OpenSSL::SSL::SSLError => e
        Rails.logger.error "Failed to modify webhooks for #{@shop.shopify_domain}. "\
          "SSLError. Error: #{e.message}"

        return false
      rescue Exception => e
        Rails.logger.error "Failed to modify webhooks for #{@shop.shopify_domain}. "\
          "This shouldn't have happened. Error: #{e.message}"

        return false
      end
    end
  end
end
