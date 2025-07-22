module Types
  class SubmitRatingInput < Types::BaseInputObject
    argument :ride_id, ID, required: true
    argument :ratee_id, ID, required: true
    argument :score, Integer, required: true
  end
end