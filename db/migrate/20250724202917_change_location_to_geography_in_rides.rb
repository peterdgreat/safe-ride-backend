class ChangeLocationToGeographyInRides < ActiveRecord::Migration[8.0]
  def up
    change_column :rides, :location, :geometry, geographic: true, srid: 4326
  end

  def down
    change_column :rides, :location, :geometry, limit: {:srid=>4326, :type=>"point"}, using: 'location::geometry(Point,4326)'
  end
end