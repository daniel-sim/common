# Preview all emails at http://localhost:3000/rails/mailers/data_request
class DataRequestPreview < ActionMailer::Preview

  # Preview this email at http://localhost:3000/rails/mailers/data_request/customers
  def customers
    DataRequestMailer.customers
  end

end
