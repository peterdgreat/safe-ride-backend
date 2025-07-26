# spec/factories/ride_requests.rb
FactoryBot.define do
  factory :ride_request do
    association :passenger, factory: :user # Passenger is a User
    pickup_time { 1.hour.from_now }
    destination { { latitude: 34.0522, longitude: -118.2437, address: "Los Angeles, CA" }.to_json }
    max_passengers { 2 }
    proposed_fare { 25.50 }
    require_verified_passengers { true }
    # Ensure pickup_location is a valid RGeo point object
    pickup_location { RGeo::Geographic.spherical_factory(srid: 4326).point(-118.2437, 34.0522) }
  end
end
