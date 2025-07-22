module Types
  class RatingType < Types::BaseObject
    field :id, ID, null: false
    field :ride, Types::RideType, null: false
    field :ratee, Types::UserType, null: false
    field :score, Integer, null: false
  end
end