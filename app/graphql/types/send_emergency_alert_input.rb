module Types
  class SendEmergencyAlertInput < Types::BaseInputObject
    argument :ride_id, ID, required: true
  end
end