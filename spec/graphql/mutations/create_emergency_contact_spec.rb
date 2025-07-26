# spec/graphql/mutations/create_emergency_contact_spec.rb
require 'rails_helper'

RSpec.describe Mutations::CreateEmergencyContact, type: :graphql do
  let(:user) { create(:user) }
  let(:contact_attributes) do
    {
      name: 'Emergency Contact',
      whatsappNumber: '+1234567890'
    }
  end

  let(:invalid_contact_attributes) do
    {
      name: nil,
      whatsappNumber: '+1234567890'
    }
  end

  let(:mutation_string) do
    %|
      mutation CreateEmergencyContact($input: CreateEmergencyContactInput!) {
        createEmergencyContact(input: $input) {
          emergencyContact {
            id
            name
            whatsappNumber
          }
          errors
        }
      }
    |
  end

  context 'when user is authenticated' do
    let(:context) { { current_user: user, schema: RideHailingSchema } }

    it 'creates a new emergency contact' do
      result = RideHailingSchema.execute(mutation_string, variables: { input: contact_attributes }, context: context)
      if result['data'].nil?
        puts "GraphQL Errors: #{result['errors'].inspect}"
      end
      expect(result['data']['createEmergencyContact']['emergencyContact']['id']).to be_present
      expect(result['data']['createEmergencyContact']['emergencyContact']['name']).to eq('Emergency Contact')
      expect(result['data']['createEmergencyContact']['errors']).to be_empty
    end

    it 'returns errors if contact creation fails' do
      result = RideHailingSchema.execute(mutation_string, variables: { input: invalid_contact_attributes }, context: context)
      if result['data'].nil?
        puts "GraphQL Errors: #{result['errors'].inspect}"
      end
      expect(result['data']).to be_nil
      expect(result['errors']).to be_present
      expect(result['errors'].first['message']).to include("Variable $input of type CreateEmergencyContactInput! was provided invalid value for name (Expected value to not be null)")
    end
  end

  context 'when user is not authenticated' do
    let(:context) { { current_user: nil, schema: RideHailingSchema } }

    it 'raises an unauthorized error' do
      result = RideHailingSchema.execute(mutation_string, variables: { input: contact_attributes }, context: context)
      expect(result['data']['createEmergencyContact']).to be_nil
      expect(result['errors'].first['message']).to eq('Not authorized')
    end
  end
end