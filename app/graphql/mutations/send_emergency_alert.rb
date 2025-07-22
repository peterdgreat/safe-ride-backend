module Mutations
  class SendEmergencyAlert < GraphQL::Schema::Mutation
    argument :input, Types::SendEmergencyAlertInput, required: true

    field :success, Boolean, null: false
    field :errors, [String], null: false

    def resolve(input:)
      ride = Ride.find_by(id: input[:ride_id])

      if ride
        authorize! :send_emergency_alert, ride
        SendEmergencyAlertJob.perform_later(ride.id)
        { success: true, errors: [] }
      else
        { success: false, errors: ["Ride not found"] }
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