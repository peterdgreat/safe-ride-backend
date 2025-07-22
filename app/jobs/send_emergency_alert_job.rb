class SendEmergencyAlertJob < ApplicationJob
  queue_as :default

  def perform(ride_id)
    ride = Ride.find(ride_id)
    user = ride.ride_request.passenger

    user.emergency_contacts.each do |contact|
      SendSmsJob.perform_later(
        contact.whatsapp_number,
        'emergency_alert',
        contact.user.preferred_language,
        {
          user_first_name: user.first_name,
          destination: ride.ride_request.destination,
        }
      )
    end
  end
end