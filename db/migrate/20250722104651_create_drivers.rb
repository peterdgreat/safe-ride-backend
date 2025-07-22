class CreateDrivers < ActiveRecord::Migration[8.0]
  def change
    create_table :drivers, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.string :license_plate
      t.string :car_model
      t.string :car_color

      t.timestamps
    end
  end
end
