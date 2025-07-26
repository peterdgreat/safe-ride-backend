# config/initializers/rgeo_factory_config.rb

RGeo::ActiveRecord::SpatialFactoryStore.instance.tap do |config|
  # By default, use the GEOS implementation for spatial columns.
  # config.default = RGeo::Geos.factory_generator

  # But use a geographic implementation for point columns.
  # This ensures that columns defined with `geographic: true` or `geography` type
  # are handled by the spherical factory.
  config.register(RGeo::Geographic.spherical_factory(srid: 4326), geo_type: "point")
end
