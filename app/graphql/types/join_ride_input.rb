module Types
  class JoinRideInput < Types::BaseInputObject
    argument :ride_id, ID, required: true
  end
end