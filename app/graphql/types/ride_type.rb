module Types
  class RideType < Types::BaseObject
    field :id, ID, null: false
    field :driver, Types::UserType, null: false
    field :ride_request, Types::RideRequestType, null: false
    field :start_time, GraphQL::Types::ISO8601DateTime, null: true
    field :end_time, GraphQL::Types::ISO8601DateTime, null: true
    field :status, String, null: false
    field :location, Types::GeometryType, null: true
    field :ride_passengers, [Types::RidePassengerType], null: false
  end
end