# spec/models/emergency_contact_spec.rb
require 'rails_helper'

RSpec.describe EmergencyContact, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:whatsapp_number) }
  end
end
