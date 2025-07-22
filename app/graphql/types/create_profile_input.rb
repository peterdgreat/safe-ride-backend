module Types
  class CreateProfileInput < Types::BaseInputObject
    argument :first_name, String, required: true
    argument :last_name, String, required: true
    argument :date_of_birth, GraphQL::Types::ISO8601Date, required: false
    argument :gender, String, required: false
    argument :profile_picture_url, String, required: false
  end
end