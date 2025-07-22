module Mutations
  class CreateProfile < GraphQL::Schema::Mutation
    argument :input, Types::CreateProfileInput, required: true

    field :profile, Types::ProfileType, null: true
    field :errors, [String], null: false

    def resolve(input:)
      profile = Profile.new(input.to_h)
      profile.user = context[:current_user]

      if profile.save
        { profile: profile, errors: [] }
      else
        { profile: nil, errors: profile.errors.full_messages }
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