module Mutations
  class CreateDriverProfile < GraphQL::Schema::Mutation
    argument :input, Types::CreateDriverProfileInput, required: true

    field :driver, Types::DriverType, null: true
    field :errors, [String], null: false

    def resolve(input:)
      driver = Driver.new(input.to_h)
      driver.user = context[:current_user]
    
      if driver.save
        { driver: driver, errors: [] }
      else
        { driver: nil, errors: driver.errors.full_messages }
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
