# spec/graphql/mutations/login_spec.rb
require 'rails_helper'

RSpec.describe Mutations::Login, type: :graphql do
  let!(:user) { create(:user, email: 'login@example.com', password: 'password') }

  let(:invalid_login_attributes) do
    {
      login: 'login@example.com',
      password: 'wrong_password'
    }
  end

  let(:mutation_string) do
    %|
      mutation Login($input: LoginInput!) {
        login(input: $input) {
          user {
            id
            email
          }
          token
          errors
        }
      }
    |
  end

  it 'logs in a user and returns a token' do
    result = RideHailingSchema.execute(mutation_string, variables: { input: { login: 'login@example.com', password: 'password' }}, context: { schema: RideHailingSchema })
    if result['data'].nil?
      puts "GraphQL Errors: #{result['errors'].inspect}"
    end
    expect(result['data']['login']['user']['id']).to eq(user.id)
    expect(result['data']['login']['token']).to be_present
    expect(result['data']['login']['errors']).to be_empty
  end

  it 'returns errors for invalid credentials' do
    result = RideHailingSchema.execute(mutation_string, variables: { input: invalid_login_attributes }, context: { schema: RideHailingSchema })
    expect(result['data']['login']).to be_nil
    expect(result['errors'].first['message']).to include('Cannot return null for non-nullable field LoginPayload.token')
  end
end