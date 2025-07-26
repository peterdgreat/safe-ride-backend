module Types
  class RideRequestType < Types::BaseObject
    field :id, ID, null: false
    field :passenger, Types::UserType, null: false
    field :pickup_time, GraphQL::Types::ISO8601DateTime, null: false
    field :destination, String, null: false # JSON will be serialized as String
    field :max_passengers, Integer, null: false
    field :proposed_fare, Float, null: false
    field :require_verified_passengers, Boolean, null: false
    field :pickup_location, Types::GeometryType, null: true
    field :estimated_fare, Float, null: true

    def pickup_location
      return unless object.pickup_location
      # Parse the WKT string back into an RGeo point
      rgeo_point = RGeo::WKRep::WKTParser.new.parse(object.pickup_location)
      { latitude: rgeo_point.y, longitude: rgeo_point.x } # RGeo points use x for longitude, y for latitude
    end
  end
end