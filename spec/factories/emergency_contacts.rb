# spec/factories/emergency_contacts.rb
FactoryBot.define do
  factory :emergency_contact do
    association :user
    name { Faker::Name.name }
    whatsapp_number { Faker::PhoneNumber.unique.cell_phone_with_country_code }
  end
end
