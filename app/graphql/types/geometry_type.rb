module Types
  class GeometryType < Types::BaseObject
    field :latitude, Float, null: false
    field :longitude, Float, null: false
  end
end