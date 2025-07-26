module Types
  class GeometryInputType < Types::BaseInputObject
    argument :lat, Float, required: true
    argument :lng, Float, required: true
  end
end