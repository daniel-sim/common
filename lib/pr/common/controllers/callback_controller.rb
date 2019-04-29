module PR
  module Common
    module Controllers
      class CallbackController < ActionController::Base
        include ShopifyApp::LoginProtection

        # Sign in callback
        def callback
          if auth_hash
            login_shop
            install_webhooks
            install_scripttags
            perform_after_authenticate_job

            shop = Shop.find_by(shopify_domain: shop_name)
            redirect_to "#{PR::Common.client_url}/users/sign_in/shopify/#{shop.user.access_token}"
          else
            flash[:error] = I18n.t('could_not_log_in')
            redirect_to [PR::Common.api_url, ShopifyApp.configuration.login_url].join
          end
        end

        protected

        def login_shop
          reset_session_options
          set_shopify_session
        end

        def reset_session_options
          request.session_options[:renew] = true
          session.delete(:_csrf_token)
        end

        def set_shopify_session
          session_store = ShopifyAPI::Session.new(
            domain: shop_name,
            token: token,
            api_version: ShopifyApp.configuration.api_version
          )

          session[:shopify] = ShopifyApp::SessionRepository.store(session_store)
          session[:shopify_domain] = shop_name
          session[:shopify_user] = associated_user
        end

        def shop_name
          auth_hash.uid
        end

        def associated_user
          return unless auth_hash['extra'].present?

          auth_hash['extra']['associated_user']
        end

        def install_webhooks
          return unless ShopifyApp.configuration.has_webhooks?

          ShopifyApp::WebhooksManager.queue(
            shop_name,
            token,
            ShopifyApp.configuration.webhooks
          )
        end

        def install_scripttags
          return unless ShopifyApp.configuration.has_scripttags?

          ScripttagsManager.queue(
            shop_name,
            token,
            ShopifyApp.configuration.scripttags
          )
        end

        def perform_after_authenticate_job
          config = ShopifyApp.configuration.after_authenticate_job

          return if config.blank? || config[:job].blank?

          method = config[:inline] ? :perform_now : :perform_later
          config[:job].send(
            method,
            shop_domain: session[:shopify_domain],
            referrer: request.env["affiliate.tag"]
          )
        end

        def auth_hash
          request.env['omniauth.auth']
        end

        def token
          auth_hash['credentials']['token']
        end
      end
    end
  end
end
