class CustomersDataRequestJob < PR::Common::ApplicationJob
  def perform(params)
    DataRequestMailer.with(data_request: params[:webhook]).customers.deliver
  end
end
