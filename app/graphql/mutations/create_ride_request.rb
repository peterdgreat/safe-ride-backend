module Mutations
  class CreateRideRequest < BaseMutation
    argument :pickup_time, GraphQL::Types::ISO8601DateTime, required: true
    argument :destination, String, required: true
    argument :max_passengers, Integer, required: true
    argument :proposed_fare, Float, required: true
    argument :require_verified_passengers, Boolean, required: true
    argument :pickup_location, Types::GeometryInputType, required: true

    field :ride_request, Types::RideRequestType, null: true
    field :errors, [String], null: false

    def resolve(pickup_time:, destination:, max_passengers:, proposed_fare:, require_verified_passengers:, pickup_location:)
      unless context[:current_user]
        return { ride_request: nil, errors: ['Authentication required'] }
      end

      # Ensure latitude and longitude are valid numbers
      unless pickup_location[:lng]&.is_a?(Numeric) && pickup_location[:lat]&.is_a?(Numeric)
        return { ride_request: nil, errors: ['Invalid pickup location coordinates'] }
      end

      factory = RGeo::Geographic.spherical_factory(srid: 4326)
      pickup_point = factory.point(pickup_location[:lng], pickup_location[:lat])

      Rails.logger.debug "Type of pickup_point: #{pickup_point.class}"
      Rails.logger.debug "Value of pickup_point: #{pickup_point.inspect}"

      ride_request = RideRequest.new(
        passenger: context[:current_user],
        pickup_time: pickup_time,
        destination: destination,
        max_passengers: max_passengers,
        proposed_fare: proposed_fare,
        require_verified_passengers: require_verified_passengers,
        pickup_location: pickup_point
      )

      if ride_request.save
        { ride_request: ride_request, errors: [] }
      else
        { ride_request: nil, errors: ride_request.errors.full_messages }
      end
    end
  end
end
