module Mutations
  class JoinRide < GraphQL::Schema::Mutation
    argument :input, Types::JoinRideInput, required: true

    field :ride, Types::RideType, null: true
    field :errors, [String], null: false

    def resolve(input:)
      ride = Ride.find_by(id: input[:ride_id])

      if ride
        authorize! :join, ride
        ride_passenger = RidePassenger.new(ride: ride, passenger: context[:current_user])
        if ride_passenger.save
          { ride: ride, errors: [] }
        else
          { ride: nil, errors: ride_passenger.errors.full_messages }
        end
      else
        { ride: nil, errors: ["Ride not found"] }
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