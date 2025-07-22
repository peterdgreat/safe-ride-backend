module Mutations
  class Logout < GraphQL::Schema::Mutation
    argument :token, String, required: true

    field :success, Boolean, null: false
    field :errors, [String], null: false

    def resolve(token:)
      # This mutation is intended to be handled by Devise JWT's revocation strategy.
      # The actual token revocation happens in Warden::JWTAuth::Middleware::RevocationManager.
      # This GraphQL mutation serves as a trigger for that process.
      { success: true, errors: [] }
    end
  end
end