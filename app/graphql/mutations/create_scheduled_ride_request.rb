module Mutations
  class CreateScheduledRideRequest < GraphQL::Schema::Mutation
    argument :input, Types::CreateScheduledRideRequestInput, required: true

    field :ride_request, Types::RideRequestType, null: true
    field :errors, [String], null: false

    def resolve(input:)
      # Check for emergency contact
      unless context[:current_user].emergency_contacts.exists?
        return { ride_request: nil, errors: ["Add emergency contact fess!"] }
      end

      ride_request = RideRequest.new(input.to_h)
      ride_request.passenger = context[:current_user]
      authorize! :create, ride_request

      if ride_request.save
        { ride_request: ride_request, errors: [] }
      else
        { ride_request: nil, errors: ride_request.errors.full_messages }
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