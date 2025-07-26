# frozen_string_literal: true

module Types
  class QueryType < Types::BaseObject
    include Pundit::Authorization


    field :driver, Types::DriverType, null: true do
      argument :id, ID, required: true
    end

    def driver(id:)
      Rails.logger.debug "QueryType#driver: current_user = #{context[:current_user]&.id}"
      driver = Driver.find_by(id: id)
      return nil unless driver # Return nil if driver not found
      Rails.logger.debug "QueryType#driver: found driver = #{driver.id}"
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
      rides = Pundit.policy_scope(context[:current_user], Ride.where("ST_DWithin(location::geometry(Point, 4326), ST_GeomFromText(?, 4326), 5000)", point.as_text))
      rides.each do |ride|
        # Recalculate estimated fare dynamically based on current passengers
        # This assumes ride_passengers are already loaded
        num_passengers = ride.ride_passengers.count
        if num_passengers > 0
          # For simplicity, assume the first passenger's dropoff for distance calculation
          # In a real scenario, this would be more complex, possibly averaging or considering routes
          first_passenger = ride.ride_passengers.first
          if first_passenger && ride.ride_request.pickup_location && first_passenger.dropoff_location
            distance_km = ride.calculate_distance(ride.ride_request.pickup_location, first_passenger.dropoff_location)
            ride.estimated_fare = ride.calculate_individual_fare(distance_km, num_passengers)
          end
        else
          # If no passengers yet, use the ride request's initial estimated fare
          ride.estimated_fare = ride.ride_request.estimated_fare
        end
      end
      rides
    end

    field :scheduled_ride_requests, [Types::RideRequestType], null: false

    def scheduled_ride_requests
      Pundit.policy_scope(context[:current_user], RideRequest) # TODO: Filter by scheduled
    end
  end
end