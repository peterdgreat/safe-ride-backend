class AddFareDetailsToRides < ActiveRecord::Migration[8.0]
  def change
    add_column :ride_requests, :pickup_location, :geometry, geographic: true, srid: 4326, null: false
    add_column :ride_requests, :estimated_fare, :float
    add_column :ride_passengers, :dropoff_location, :geometry, geographic: true, srid: 4326, null: false
    add_column :ride_passengers, :fare_amount, :float

    add_index :ride_requests, :pickup_location, using: :gist
    add_index :ride_passengers, :dropoff_location, using: :gist
  end
end