require "active_resource"
require "json"
require "net/http"
require "openssl"

module Exceptions
  module Shopify
    def self.intercept(shopify_domain = nil, &block)
      yield
    rescue StandardError => exception
      raise convert(exception, shopify_domain)
    end

    def self.convert(exception, shopify_domain = nil)
      return exception if shopify_domain.blank?

      # Some of these may be subclasses, so be careful with ordering
      case exception
      when ActiveResource::UnauthorizedAccess
        return ShopUninstalled.new(shopify_domain, exception.message)
      when ActiveResource::ForbiddenAccess
        return ShopFraudulent.new(shopify_domain, exception.message)
      when ActiveResource::ClientError
        return convert_from_client_error(exception, shopify_domain)
      when ActiveResource::ServerError
        return ServerError.new(shopify_domain, exception.message)
      when JSON::ParserError
        return JsonError.new(shopify_domain, exception.message)
      when Errno::ECONNRESET, OpenSSL::SSL::SSLError, Net::ReadTimeout, EOFError, ActiveResource::SSLError, ActiveResource::TimeoutError
        return MiscTransient.new(shopify_domain, exception.message)
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
          message << "shop=#{@shopify_domain}" if @shopify_domain
        end
      end
    end

    class ShopLocked < Base; end
    class ShopFrozen < Base; end
    class ShopUninstalled < Base; end
    class ShopFraudulent < Base; end

    class Transient < Base; end
    class ServerError < Transient; end
    class JsonError < Transient; end
    class MiscTransient < Transient; end
  end
end
