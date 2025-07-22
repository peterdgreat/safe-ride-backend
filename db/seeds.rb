# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)

# Create 10 verified drivers
10.times do
  user = User.create!(
    email: Faker::Internet.unique.email,
    phone_number: Faker::PhoneNumber.unique.subscriber_number(length: 10),
    password: 'password',
    password_confirmation: 'password',
    first_name: Faker::Name.first_name,
    last_name: Faker::Name.last_name,
    is_verified: true
  )
  Driver.create!(
    user: user,
    license_plate: Faker::Vehicle.license_plate,
    car_model: Faker::Vehicle.make_and_model,
    car_color: Faker::Vehicle.color
  )
end

# Create 5 passengers with emergency contacts and 5 scheduled ride requests
5.times do
  user = User.create!(
    email: Faker::Internet.unique.email,
    phone_number: Faker::PhoneNumber.unique.subscriber_number(length: 10),
    password: 'password',
    password_confirmation: 'password',
    first_name: Faker::Name.first_name,
    last_name: Faker::Name.last_name,
    is_verified: false
  )

  EmergencyContact.create!(
    user: user,
    name: Faker::Name.name,
    whatsapp_number: Faker::PhoneNumber.unique.subscriber_number(length: 10)
  )

  RideRequest.create!(
    passenger: user,
    pickup_time: Faker::Time.forward(days: 7, period: :day),
    destination: { latitude: Faker::Address.latitude, longitude: Faker::Address.longitude }.to_json,
    max_passengers: Faker::Number.between(from: 1, to: 4),
    proposed_fare: Faker::Number.decimal(l_digits: 3, r_digits: 2),
    require_verified_passengers: Faker::Boolean.boolean
  )
end