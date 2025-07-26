# spec/policies/ride_policy_spec.rb
require 'rails_helper'

RSpec.describe RidePolicy, type: :policy do
  let(:customer_user) { create(:user) }
  let(:driver_user) { create(:user) }
  let!(:driver_profile) { create(:driver, user: driver_user) } # Ensure driver_user has a driver profile

  let(:ride_request) { create(:ride_request, passenger: customer_user) } # Assuming ride_request factory
  let(:ride) { create(:ride, driver: driver_user, ride_request: ride_request) } # Assuming ride factory

  subject { described_class.new(user, ride) } # Initialize policy with user and ride record

  describe 'create?' do
    context 'when user is a driver' do
      let(:user) { driver_user }
      it 'grants access' do
        expect(subject.create?).to be_truthy
      end
    end

    context 'when user is not a driver' do
      let(:user) { customer_user }
      it 'denies access' do
        expect(subject.create?).to be_falsey
      end
    end
  end

  describe 'join?' do
    context 'when user is a customer' do
      let(:user) { customer_user }
      it 'grants access' do
        expect(subject.join?).to be_truthy
      end
    end

    context 'when user is a driver' do
      let(:user) { driver_user }
      it 'grants access' do
        expect(subject.join?).to be_truthy
      end
    end
  end

  describe 'create_share?' do
    context 'when user is a customer' do
      let(:user) { customer_user }
      it 'grants access' do
        expect(subject.create_share?).to be_truthy
      end
    end

    context 'when user is a driver' do
      let(:user) { driver_user }
      it 'grants access' do
        expect(subject.create_share?).to be_truthy
      end
    end
  end

  describe 'send_emergency_alert?' do
    context 'when user is a customer' do
      let(:user) { customer_user }
      it 'grants access' do
        expect(subject.send_emergency_alert?).to be_truthy
      end
    end

    context 'when user is a driver' do
      let(:user) { driver_user }
      it 'grants access' do
        expect(subject.send_emergency_alert?).to be_truthy
      end
    end
  end

  describe 'Scope' do
    let(:scope) { Ride.all }
    subject { described_class::Scope.new(customer_user, scope) }

    it 'returns all rides for now' do
      # This tests the current broad implementation of scope.all
      expect(subject.resolve).to eq(scope)
    end
  end
end
