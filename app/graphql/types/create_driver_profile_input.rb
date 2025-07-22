module Types
  class CreateDriverProfileInput < Types::BaseInputObject
    argument :license_plate, String, required: true
    argument :car_model, String, required: true
    argument :car_color, String, required: true
  end
end