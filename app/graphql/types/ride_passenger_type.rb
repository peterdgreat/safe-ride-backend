module Types
  class RidePassengerType < Types::BaseObject
    field :id, ID, null: false
    field :ride, Types::RideType, null: false
    field :passenger, Types::UserType, null: false
    field :dropoff_location, Types::GeometryType, null: false
    field :fare_amount, Float, null: true
  end
end