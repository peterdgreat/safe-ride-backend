class CreateRides < ActiveRecord::Migration[8.0]
  def change
    create_table :rides, id: :uuid do |t|
      t.references :driver, null: false, foreign_key: { to_table: :users }, type: :uuid
      t.references :ride_request, null: false, foreign_key: true, type: :uuid
      t.datetime :start_time
      t.datetime :end_time
      t.string :status

      t.timestamps
    end
  end
end
