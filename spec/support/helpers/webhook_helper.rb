module WebhookHelper
  def generate_hmac(data)
    Base64.encode64(
      OpenSSL::HMAC.digest(
        OpenSSL::Digest.new('sha256'),
        ShopifyApp.configuration.secret,
        data
      )
    ).strip
  end
end
