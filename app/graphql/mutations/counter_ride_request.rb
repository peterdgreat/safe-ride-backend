module Mutations
  class CounterRideRequest < BaseMutation
    argument :ride_request_id, ID, required: true
    argument :new_proposed_fare, Float, required: true

    field :ride_request, Types::RideRequestType, null: true
    field :errors, [String], null: false

    def resolve(ride_request_id:, new_proposed_fare:)
      ride_request = RideRequest.find_by(id: ride_request_id)

      unless ride_request
        return { ride_request: nil, errors: ['Ride request not found'] }
      end

      # Only drivers can counter a ride request
      unless context[:current_user]&.driver?
        return { ride_request: nil, errors: ['Not authorized'] }
      end

      ride_request.estimated_fare = new_proposed_fare

      if ride_request.save
        # Notify passengers of the counteroffer
        ride_request.passengers.each do |passenger|
          message = "Driver has counter-offered a new fare for your ride request. New estimated fare: #{new_proposed_fare}"
          SendSmsJob.perform_later(passenger.phone_number, message)
          SendWhatsappJob.perform_later(passenger.phone_number, message)
        end

        { ride_request: ride_request, errors: [] }
      else
        { ride_request: nil, errors: ride_request.errors.full_messages }
      end
    end
  end
end
