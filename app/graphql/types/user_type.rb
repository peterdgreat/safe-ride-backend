module Types
  class UserType < Types::BaseObject
    field :id, ID, null: false
    field :email, String, null: false
    field :phone_number, String, null: true
    field :first_name, String, null: true
    field :last_name, String, null: true
    field :is_verified, Boolean, null: false
    field :preferred_language, String, null: false
    field :profile, Types::ProfileType, null: true
    field :emergency_contacts, [Types::EmergencyContactType], null: true
    field :driver_profile, Types::DriverType, null: true
  end
end