class SendWhatsappJob < ApplicationJob
  queue_as :default

  def perform(recipient, message)
    # Africa's Talking API integration
    # Replace with actual API calls to Africa's Talking
    Rails.logger.info "Sending WhatsApp to #{recipient}: #{message}"
    # AfricaTalking.send_whatsapp(recipient, message)
  end
end