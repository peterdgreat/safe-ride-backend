module Mutations
  class SubmitRating < GraphQL::Schema::Mutation
    argument :input, Types::SubmitRatingInput, required: true

    field :rating, Types::RatingType, null: true
    field :errors, [String], null: false

    def resolve(input:)
      ride = Ride.find_by(id: input[:ride_id])
      ratee = User.find_by(id: input[:ratee_id])

      unless ride && ratee
        return { rating: nil, errors: ["Ride or Ratee not found"] }
      end

      rating = Rating.new(input.to_h)
      rating.ride = ride
      rating.ratee = ratee

      authorize! :create, rating

      if rating.save
        { rating: rating, errors: [] }
      else
        { rating: nil, errors: rating.errors.full_messages }
      end
    end

    private

    def authorize!(action, subject)
      unless Pundit.policy(context[:current_user], subject).public_send("#{action}?")
        raise GraphQL::ExecutionError, 'Not authorized'
      end
    end
  end
end