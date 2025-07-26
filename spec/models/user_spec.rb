# spec/models/user_spec.rb
require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
    it { should validate_presence_of(:phone_number) }
    it { should validate_uniqueness_of(:phone_number) }
    it { should validate_presence_of(:first_name) }
    it { should validate_presence_of(:last_name) }
    it { should validate_length_of(:password).is_at_least(6) }
  end

  describe 'associations' do
    it { should have_one(:profile).dependent(:destroy) }
    it { should have_many(:emergency_contacts).dependent(:destroy) }
    it { should have_one(:driver).dependent(:destroy) }
  end

  describe '#generate_jwt' do
    let(:user) { create(:user) } # Assuming you have a user factory

    it 'generates a valid JWT token' do
      token = user.generate_jwt
      expect(token).to be_present
      decoded_token = JWT.decode(token, Rails.application.credentials.devise_jwt_secret_key!, true, algorithm: 'HS256')
      expect(decoded_token[0]['jti']).to eq(user.jti)
      expect(decoded_token[0]['sub']).to eq(user.id)
    end
  end

  describe '.find_for_database_authentication' do
    let!(:user) { create(:user, email: 'test2@example.com', phone_number: '+2348112345678') }

    it 'finds user by email' do
      expect(User.find_for_database_authentication(login: 'test2@example.com')).to eq(user)
    end

    it 'finds user by phone number' do
      expect(User.find_for_database_authentication(login: '+2348112345678')).to eq(user)
    end

    it 'returns nil if user not found' do
      expect(User.find_for_database_authentication(login: 'nonexistent@example.com')).to be_nil
    end
  end
end
