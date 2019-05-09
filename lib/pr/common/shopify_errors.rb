module PR
  module Common
    module ShopifyErrors
      def self.convert(exception, shopify_domain = nil)
        return exception if shopify_domain.blank?

        case exception
        when ActiveResource::ClientError
          return convert_from_client_error(exception, shopify_domain)
        when ActiveResource::UnauthorizedAccess
          return ShopUninstalled.new(shopify_domain, exception.message)
        when ActiveResource::ServerError
          return ServerError.new(shopify_domain, exception.message)
        when JSON::ParserError
          return JsonError.new(shopify_domain, exception.message)
        end

        exception
      end

      def self.convert_from_client_error(exception, shopify_domain)
        case exception.message
        when "Failed.  Response code = 423.  Response message = Locked."
          return ShopLocked.new(shopify_domain, exception.message)
        when "Failed.  Response code = 402.  Response message = Payment Required."
          return ShopFrozen.new(shopify_domain, exception.message)
        end

        exception
      end

      class Base < StandardError
        def initialize(shopify_domain = nil, message = nil)
          @shopify_domain = shopify_domain
          @message = message
        end

        def to_s
          "".tap do |message|
            message << "#{@message}. " if @message
            message << "shop=#{@shopify_domain}"
          end
        end
      end

      class ShopLocked < Base; end
      class ShopFrozen < Base; end
      class ShopUninstalled < Base; end
      class ServerError < Base; end
      class JsonError < Base; end
    end
  end
end
