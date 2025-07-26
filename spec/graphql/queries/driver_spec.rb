# spec/graphql/queries/driver_spec.rb
require 'rails_helper'
require './app/graphql/ride_hailing_schema' # Explicitly require the schema

RSpec.describe 'Driver Query', type: :graphql do
  let(:query_string) do
    %|
      query GetDriver($id: ID!) {
        driver(id: $id) {
          id
          user {
            id
            email
          }
          licensePlate
          carModel
          carColor
        }
      }
    |
  end

  let(:customer_user) { create(:user) }
  let(:driver_user) { create(:user) }
  let!(:driver_profile) { create(:driver, user: driver_user) }

  context 'when authenticated as a customer' do
    let(:context) { { current_user: customer_user, schema: RideHailingSchema } }

    it 'returns the driver information' do
      result = RideHailingSchema.execute(query_string, variables: { id: driver_profile.id }, context: context)
      expect(result['data']['driver']['id']).to eq(driver_profile.id)
      expect(result['data']['driver']['user']['id']).to eq(driver_user.id)
      expect(result['data']['driver']['licensePlate']).to eq(driver_profile.license_plate)
    end

    it 'returns nil if driver not found' do
      result = RideHailingSchema.execute(query_string, variables: { id: 'non-existent-id' }, context: context)
      expect(result['data']['driver']).to be_nil
    end
  end

  context 'when not authenticated' do
    let(:context) { { current_user: nil, schema: RideHailingSchema } }

    it 'raises an unauthorized error' do
      # Pundit will raise an error if no user is present and policy requires it
      expect { RideHailingSchema.execute(query_string, variables: { id: driver_profile.id }, context: context) }
        .to raise_error(Pundit::NotAuthorizedError)
    end
  end
end