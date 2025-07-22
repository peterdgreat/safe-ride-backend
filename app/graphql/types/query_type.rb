# frozen_string_literal: true

module Types
  class QueryType < Types::BaseObject
    include Pundit::Authorization


    field :driver, Types::DriverType, null: true do
      argument :id, ID, required: true
    end

    def driver(id:)
      driver = Driver.find_by(id: id)
      return nil unless driver # Return nil if driver not found
      Pundit.authorize(context[:current_user], driver, :show?)
      driver
    end

    field :profile, Types::ProfileType, null: true

    def profile
      profile = context[:current_user]&.profile
      return nil unless profile # Return nil if profile not found
      Pundit.authorize(context[:current_user], profile, :show?)
      profile
    end

    field :nearby_rides, [Types::RideType], null: false do
      argument :lat, Float, required: true
      argument :lng, Float, required: true
    end

    def nearby_rides(lat:, lng:)
      factory = RGeo::Geographic.spherical_factory(srid: 4326)
      point = factory.point(lng, lat)
      Pundit.policy_scope(context[:current_user], Ride.where("ST_DWithin(location::geometry(Point, 4326), ST_GeomFromText(?, 4326), 5000)", point.as_text))
    end

    field :scheduled_ride_requests, [Types::RideRequestType], null: false

    def scheduled_ride_requests
      Pundit.policy_scope(context[:current_user], RideRequest) # TODO: Filter by scheduled
    end
  end
end
