# spec/models/driver_spec.rb
require 'rails_helper'

RSpec.describe Driver, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
  end

  describe 'validations' do
    it { should validate_presence_of(:license_plate) }
    it { should validate_presence_of(:car_model) }
    it { should validate_presence_of(:car_color) }
  end
end
