module Mutations
  class CreateEmergencyContact < GraphQL::Schema::Mutation
    argument :input, Types::CreateEmergencyContactInput, required: true

    field :emergency_contact, Types::EmergencyContactType, null: true
    field :errors, [String], null: false

    def resolve(input:)
      emergency_contact = EmergencyContact.new(input.to_h)
      emergency_contact.user = context[:current_user]
      authorize! :create, emergency_contact

      if emergency_contact.save
        { emergency_contact: emergency_contact, errors: [] }
      else
        { emergency_contact: nil, errors: emergency_contact.errors.full_messages }
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