class RidePassenger < ApplicationRecord
  include FareCalculator

  belongs_to :ride
  belongs_to :passenger, class_name: 'User'

  # Define geographic columns
  attribute :dropoff_location, :point

  # Callbacks
  before_save :calculate_fare_amount

  private

  def calculate_fare_amount
    # Calculate individual fare based on ride request's pickup location and this passenger's dropoff
    # and the total number of passengers in the ride.
    # This assumes ride_request and ride are already associated.
    if ride.present? && ride.ride_request.present? && dropoff_location.present?
      distance_km = calculate_distance(ride.ride_request.pickup_location, dropoff_location)
      num_passengers = ride.ride_passengers.count # Count all passengers in the ride
      self.fare_amount = calculate_individual_fare(distance_km, num_passengers)
    else
      self.fare_amount = 0.0
    end
  end

end
