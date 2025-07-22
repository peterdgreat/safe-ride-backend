# frozen_string_literal: true

module Types
  class QueryType < Types::BaseObject


    field :driver, Types::DriverType, null: true do
      argument :id, ID, required: true
    end

    def driver(id:)
      driver = Driver.find_by(id: id)
      authorize driver, :show?
      driver
    end

    field :profile, Types::ProfileType, null: true

    def profile
      profile = context[:current_user]&.profile
      authorize profile, :show?
      profile
    end

    field :nearby_rides, [Types::RideType], null: false do
      argument :lat, Float, required: true
      argument :lng, Float, required: true
    end

    def nearby_rides(lat:, lng:)
      factory = RGeo::Geographic.spherical_factory(srid: 4326)
      point = factory.point(lng, lat)
      policy_scope(Ride.where("ST_DWithin(location, ?, 5000)", point))
    end

    field :scheduled_ride_requests, [Types::RideRequestType], null: false

    def scheduled_ride_requests
      policy_scope(RideRequest) # TODO: Filter by scheduled
    end
  end
end
