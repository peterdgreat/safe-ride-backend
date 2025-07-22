class AddLocationToRides < ActiveRecord::Migration[8.0]
  def change
    add_column :rides, :location, :geometry, limit: {:srid=>4326, :type=>"point"}
    add_index :rides, :location, using: :gist
  end
end