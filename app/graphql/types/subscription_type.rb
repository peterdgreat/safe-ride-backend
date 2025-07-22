module Types
  class SubscriptionType < Types::BaseObject
    field :ride_updated, Types::RideType, null: false, description: "A ride was updated" do
      argument :ride_id, ID, required: true
    end

    def ride_updated(ride_id:)
      # This method is called when the subscription is established
      # and is responsible for returning the initial value.
      # Subsequent updates are pushed via ActionCable.
      Ride.find(ride_id)
    end
  end
end