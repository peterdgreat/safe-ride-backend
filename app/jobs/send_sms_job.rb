class SendSmsJob < ApplicationJob
  queue_as :default

  def perform(recipient, message)
    # Africa's Talking API integration
    # Replace with actual API calls to Africa's Talking
    Rails.logger.info "Sending SMS to #{recipient}: #{message}"
    # AfricaTalking.send_sms(recipient, message)
  end
end