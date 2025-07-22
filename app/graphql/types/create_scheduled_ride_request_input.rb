module Types
  class CreateScheduledRideRequestInput < Types::BaseInputObject
    argument :pickup_time, GraphQL::Types::ISO8601DateTime, required: true
    argument :destination, String, required: true # JSON as String
    argument :max_passengers, Integer, required: true
    argument :proposed_fare, Float, required: true
    argument :require_verified_passengers, Boolean, required: true
  end
end