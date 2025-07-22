module Types
  class CreateRideInput < Types::BaseInputObject
    argument :ride_request_id, ID, required: true
    argument :driver_id, ID, required: true
    argument :location, String, required: true # WKT format, e.g., "POINT(-118.2437 34.0522)"
  end
end