class RideRequest < ApplicationRecord
  include FareCalculator

  belongs_to :passenger, class_name: 'User'
  has_many :ride_passengers

  # Custom setter for pickup_location to handle RGeo objects
  def pickup_location=(value)
    if value.is_a?(RGeo::Feature::Point)
      super(value.as_text) # Convert RGeo point to WKT string
    else
      super(value) # Handle other cases (e.g., WKT string directly)
    end
  end

  # Callbacks
  before_save :calculate_estimated_fare

  private

  def calculate_estimated_fare
    # For initial estimation, assume a single passenger and a default distance
    # This will be updated dynamically as passengers join
    estimated_distance_km = 10.0 # Placeholder distance
    self.estimated_fare = calculate_individual_fare(estimated_distance_km, 1)
  end
end