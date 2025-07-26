module FareCalculator
  extend ActiveSupport::Concern

  included do
    # Base fare and per-km rate
    BASE_FARE = 200.0
    PER_KM_RATE = 50.0

    # Discount percentages based on number of passengers
    DISCOUNT_RATES = {
      1 => 0.0,   # 0% discount for 1 passenger
      2 => 0.2,   # 20% discount for 2 passengers
      3 => 0.3,   # 30% discount for 3 passengers
      4 => 0.4    # 40% discount for 4 passengers
    }.freeze

    def calculate_individual_fare(distance_km, num_passengers)
      # Calculate base fare for the distance
      individual_base_fare = BASE_FARE + (distance_km * PER_KM_RATE)

      # Apply shared ride discount
      discount = DISCOUNT_RATES[num_passengers] || 0.0
      individual_base_fare * (1 - discount)
    end

    def calculate_distance(start_location, end_location)
      return 0.0 unless start_location.present? && end_location.present?

      # ST_Distance returns distance in meters for geographic coordinates
      # Convert to kilometers
      start_location.distance(end_location) / 1000.0
    end
  end
end
