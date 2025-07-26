# spec/factories/rides.rb
FactoryBot.define do
  factory :ride do
    association :driver, factory: :user # Driver is a User
    association :ride_request
    location { RGeo::Geographic.spherical_factory(srid: 4326).point(-118.2437, 34.0522) } # Assign as RGeo point object
  end
end