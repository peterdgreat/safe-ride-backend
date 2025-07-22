class SendSmsJob < ApplicationJob
  queue_as :default

  def perform(phone_number, message_key, locale, interpolation_options = {})
    I18n.with_locale(locale) do
      message = I18n.t(message_key, interpolation_options)
      AT = AfricasTalking::Application.new(ENV['AFRICASTALKING_USERNAME'], ENV['AFRICASTALKING_API_KEY'])
      sms = AT.sms
      options = { 'to' => phone_number, 'message' => message }
      sms.send options
    end
  end
end