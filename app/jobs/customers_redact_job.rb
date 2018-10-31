class CustomersRedactJob < PR::Common::ApplicationJob
  # This should be implemented per app.
  # Customer PII should be cleared
  # If orders provided (and stored), PII on those should be cleared
  # example payload:
  # {
  #   "shop_id": 954889,
  #   "shop_domain": "snowdevil.myshopify.com",
  #   "customer": {
  #     "id": 191167,
  #     "email": "john@email.com",
  #     "phone": "555-625-1199"
  #   },
  #   "orders_to_redact": [299938, 280263, 220458]
  # }
  def perform(_params); end
end
