module Types
  class EmergencyContactType < Types::BaseObject
    field :id, ID, null: false
    field :user, Types::UserType, null: false
    field :name, String, null: false
    field :whatsapp_number, String, null: false
  end
end