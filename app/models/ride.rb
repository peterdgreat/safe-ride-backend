class Ride < ApplicationRecord
  belongs_to :driver, class_name: 'User'
  belongs_to :ride_request
  has_many :ride_passengers
  has_many :passengers, through: :ride_passengers, source: :passenger

  

  after_save do
    RideHailingSchema.subscriptions.trigger(
      :ride_updated,
      { ride_id: id },
      self
    )
  end
end