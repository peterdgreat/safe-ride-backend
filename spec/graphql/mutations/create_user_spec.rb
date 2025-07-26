# spec/graphql/mutations/create_user_spec.rb
require 'rails_helper'

RSpec.describe Mutations::CreateUser, type: :graphql do
  let(:user_attributes) do
    {
      email: 'test@example.com',
      password: 'password',
      passwordConfirmation: 'password',
      firstName: 'John',
      lastName: 'Doe',
      phoneNumber: '+1234567890'
    }
  end

  let(:invalid_user_attributes) do
    {
      email: nil,
      password: 'password',
      passwordConfirmation: 'password',
      firstName: 'John',
      lastName: 'Doe',
      phoneNumber: '+1234567890'
    }
  end

  let(:mutation_string) do
    %|
      mutation CreateUser($input: CreateUserInput!) {
        createUser(input: $input) {
          user {
            id
            email
          }
          errors
        }
      }
    |
  end

  it 'creates a new user' do
    result = RideHailingSchema.execute(mutation_string, variables: { input: user_attributes }, context: { schema: RideHailingSchema })
    if result['data'].nil?
      puts "GraphQL Errors: #{result['errors'].inspect}"
    end
    expect(result['data']['createUser']['user']['id']).to be_present
    expect(result['data']['createUser']['user']['email']).to eq('test@example.com')
    expect(result['data']['createUser']['errors']).to be_empty
  end

  it 'returns errors if user creation fails' do
    result = RideHailingSchema.execute(mutation_string, variables: { input: invalid_user_attributes }, context: { schema: RideHailingSchema })
    if result['data'].nil?
      puts "GraphQL Errors: #{result['errors'].inspect}"
    end
    expect(result['data']).to be_nil
    expect(result['errors']).to be_present
    expect(result['errors'].first['message']).to include("Variable $input of type CreateUserInput! was provided invalid value for email (Expected value to not be null)")
  end
end