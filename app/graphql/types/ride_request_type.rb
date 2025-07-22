module Types
  class RideRequestType < Types::BaseObject
    field :id, ID, null: false
    field :passenger, Types::UserType, null: false
    field :pickup_time, GraphQL::Types::ISO8601DateTime, null: false
    field :destination, String, null: false # JSON will be serialized as String
    field :max_passengers, Integer, null: false
    field :proposed_fare, Float, null: false
    field :require_verified_passengers, Boolean, null: false
  end
end