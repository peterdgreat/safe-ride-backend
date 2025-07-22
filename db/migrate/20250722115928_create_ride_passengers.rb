class CreateRidePassengers < ActiveRecord::Migration[8.0]
  def change
    create_table :ride_passengers, id: :uuid do |t|
      t.references :ride, null: false, foreign_key: true, type: :uuid
      t.references :passenger, null: false, foreign_key: { to_table: :users }, type: :uuid

      t.timestamps
    end
  end
end
