module Mutations
  class CreateUser < GraphQL::Schema::Mutation
    argument :input, Types::CreateUserInput, required: true

    field :user, Types::UserType, null: true
    field :errors, [String], null: false

    def resolve(input:)
      user = User.new(input.to_h)
      puts "User attributes: #{user.attributes}"
      if user.save
        { user: user, errors: [] }
      else
        puts "User errors: #{user.errors.full_messages}"
        { user: nil, errors: user.errors.full_messages }
      end
    end


  end
end
