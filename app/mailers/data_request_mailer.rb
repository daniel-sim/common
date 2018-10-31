class DataRequestMailer < ApplicationMailer
  def customers
    @data_request = params[:data_request]

    mail to: Settings.support_email,
             subject: 'Customer Data Request'
  end
end
