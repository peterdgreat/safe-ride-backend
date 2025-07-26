module Types
  class CreateRideRequestInput < Types::BaseInputObject
    argument :pickup_time, GraphQL::Types::ISO8601DateTime, required: true
    argument :destination, String, required: true
    argument :max_passengers, Integer, required: true
    argument :proposed_fare, Float, required: true
    argument :require_verified_passengers, Boolean, required: true
    argument :pickup_location, Types::GeometryInputType, required: true
  end
end