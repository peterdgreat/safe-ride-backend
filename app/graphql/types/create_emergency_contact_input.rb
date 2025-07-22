module Types
  class CreateEmergencyContactInput < Types::BaseInputObject
    argument :name, String, required: true
    argument :whatsapp_number, String, required: true
  end
end