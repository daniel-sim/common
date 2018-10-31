class ApplicationMailer < ActionMailer::Base
  default from: Settings.support_email

  layout 'mailer'
end

