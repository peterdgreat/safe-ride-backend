module Types
  class DriverType < Types::BaseObject
    field :id, ID, null: false
    field :user, Types::UserType, null: false
    field :license_plate, String, null: true
    field :car_model, String, null: true
    field :car_color, String, null: true
  end
end