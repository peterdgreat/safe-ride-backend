class CreateRideRequests < ActiveRecord::Migration[8.0]
  def change
    create_table :ride_requests, id: :uuid do |t|
      t.references :passenger, null: false, foreign_key: { to_table: :users }, type: :uuid
      t.datetime :pickup_time
      t.json :destination
      t.integer :max_passengers
      t.float :proposed_fare
      t.boolean :require_verified_passengers

      t.timestamps
    end
  end
end
