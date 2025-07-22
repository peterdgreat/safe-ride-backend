class CreateRatings < ActiveRecord::Migration[8.0]
  def change
    create_table :ratings, id: :uuid do |t|
      t.references :ride, null: false, foreign_key: true, type: :uuid
      t.references :ratee, null: false, foreign_key: { to_table: :users }, type: :uuid
      t.integer :score

      t.timestamps
    end
  end
end
