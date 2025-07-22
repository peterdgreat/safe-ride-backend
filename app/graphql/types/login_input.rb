module Types
  class LoginInput < Types::BaseInputObject
    argument :login, String, required: true
    argument :password, String, required: true
  end
end