module Mutations
  class CreateRide < GraphQL::Schema::Mutation
    argument :input, Types::CreateRideInput, required: true

    field :ride, Types::RideType, null: true
    field :errors, [String], null: false

    def resolve(input:)
      ride_request = RideRequest.find_by(id: input[:ride_request_id])
      driver_profile = Driver.find_by(id: input[:driver_id])
      driver_user = driver_profile.user if driver_profile

      unless ride_request && driver_user
        return { ride: nil, errors: ["Ride request or driver not found"] }
      end

      ride = Ride.new(
        ride_request: ride_request,
        driver: driver_user, # Pass the User object here
        location: input[:location] # Pass the WKT string directly
      )

      if ride.save
        { ride: ride, errors: [] }
      else
        { ride: nil, errors: ride.errors.full_messages }
      end
    end

    private

    def authorize!(action, subject)
      unless Pundit.policy(context[:current_user], subject).public_send("#{action}?")
        raise GraphQL::ExecutionError, 'Not authorized'
      end
    end
  end
end