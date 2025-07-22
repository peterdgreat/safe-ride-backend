module Types
  class RideType < Types::BaseObject
    field :id, ID, null: false
    field :driver, Types::UserType, null: false
    field :ride_request, Types::RideRequestType, null: false
    field :start_time, GraphQL::Types::ISO8601DateTime, null: true
    field :end_time, GraphQL::Types::ISO8601DateTime, null: true
    field :status, String, null: false
    field :location, String, null: true # PostGIS point will be serialized as String
  end
end