# spec/factories/drivers.rb
FactoryBot.define do
  factory :driver do
    association :user # Creates a user and associates it
    license_plate { Faker::Alphanumeric.unique.alphanumeric(number: 7).upcase }
    car_model { Faker::Vehicle.make_and_model }
    car_color { Faker::Vehicle.color }
  end
end
