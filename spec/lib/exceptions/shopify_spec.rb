require "spec_helper"
require "exceptions/shopify"

describe Exceptions::Shopify do
  let(:shopify_domain) { "pluginuseful.myshopify.com" }

  def converts(from_error, to_error_class)
    converted_error = Exceptions::Shopify.convert(from_error, shopify_domain)

    expect(converted_error).to be_a(to_error_class)
  end

  describe ".intercept" do
    it "calls .convert when an error is raised" do
      exception = StandardError.new
      new_exception = StandardError.new

      allow(subject)
        .to receive(:convert)
        .with(exception, shopify_domain)
        .and_return(new_exception)

      expect do
        subject.intercept(shopify_domain) do
          raise exception
        end
      end.to raise_error(new_exception)
    end
  end

  describe ".convert" do
    it "converts an ActiveResource::ClientError into Exceptions::Shopify::ShopLocked" do
      error = ActiveResource::ClientError.new(OpenStruct.new(code: 423, message: "Locked"))

      converts(error, Exceptions::Shopify::ShopLocked)
    end

    it "converts an ActiveResource::ClientError into Exceptions::Shopify::ShopFrozen" do
      message = "Failed.  Response code = 402.  Response message = Payment Required."
      error = ActiveResource::ClientError.new(OpenStruct.new(code: 402, message: "Payment Required"))

      converts(error, Exceptions::Shopify::ShopFrozen)
    end

    it "converts an ActiveResource::UnauthorizedAccess into Exceptions::Shopify::ShopUninstalled" do
      error = ActiveResource::UnauthorizedAccess.new(nil)

      converts(error, Exceptions::Shopify::ShopUninstalled)
    end

    it "converts an ActiveResource::ServerError into Exceptions::Shopify::ServerError" do
      error = ActiveResource::ServerError.new(nil)

      converts(error, Exceptions::Shopify::ServerError)
    end

    it "converts a JSON::ParserError into Exceptions::Shopify::JsonError" do
      error = JSON::ParserError.new(nil)

      converts(error, Exceptions::Shopify::JsonError)
    end

    it "converts an Errno::ECONNRESET into Exceptions::Shopify::MiscTransient" do
      error = Errno::ECONNRESET.new(nil)

      converts(error, Exceptions::Shopify::MiscTransient)
    end

    it "converts an OpenSSL::SSL::SSLError into Exceptions::Shopify::MiscTransient" do
      error = OpenSSL::SSL::SSLError.new(nil)

      converts(error, Exceptions::Shopify::MiscTransient)
    end

    it "converts a Net::ReadTimeout into Exceptions::Shopify::MiscTransient" do
      error = Net::ReadTimeout.new(nil)

      converts(error, Exceptions::Shopify::MiscTransient)
    end

    it "converts a EOFError into Exceptions::Shopify::MiscTransient" do
      error = EOFError.new(nil)

      converts(error, Exceptions::Shopify::MiscTransient)
    end

    it "converts a ActiveResource::SSLError into Exceptions::Shopify::MiscTransient" do
      error = ActiveResource::SSLError.new(nil)

      converts(error, Exceptions::Shopify::MiscTransient)
    end

    it "converts a ActiveResource::TimeoutError into Exceptions::Shopify::MiscTransient" do
      error = ActiveResource::TimeoutError.new(nil)

      converts(error, Exceptions::Shopify::MiscTransient)
    end
  end
end
