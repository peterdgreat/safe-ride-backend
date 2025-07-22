module Mutations
  class Login < GraphQL::Schema::Mutation
    argument :input, Types::LoginInput, required: true

    field :user, Types::UserType, null: true
    field :token, String, null: false
    field :errors, [String], null: false

    def resolve(input:)
      user = User.find_for_database_authentication(login: input[:login])

      if user&.valid_password?(input[:password])
        token = user.generate_jwt
        { user: user, token: token, errors: [] }
      else
        { user: nil, token: nil, errors: ["Invalid credentials"] }
      end
    end
  end
end
