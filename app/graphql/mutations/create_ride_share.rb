module Mutations
  class CreateRideShare < GraphQL::Schema::Mutation
    argument :input, Types::CreateRideShareInput, required: true

    field :shareable_link, String, null: true
    field :errors, [String], null: false

    def resolve(input:)
      ride = Ride.find_by(id: input[:ride_id])

      if ride
        authorize! :create_share, ride
        # Generate shareable link logic here
        shareable_link = "https://saferideng.com/rides/#{ride.id}/share"
        { shareable_link: shareable_link, errors: [] }
      else
        { shareable_link: nil, errors: ["Ride not found"] }
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
