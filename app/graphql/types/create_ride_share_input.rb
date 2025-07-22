module Types
  class CreateRideShareInput < Types::BaseInputObject
    argument :ride_id, ID, required: true
  end
end