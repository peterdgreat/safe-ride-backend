module Types
  class CreateUserInput < Types::BaseInputObject
    argument :email, String, required: true
    argument :password, String, required: true
    argument :password_confirmation, String, required: true
    argument :first_name, String, required: true
    argument :last_name, String, required: true
    argument :phone_number, String, required: true
  end
end