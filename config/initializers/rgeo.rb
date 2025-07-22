# config/initializers/rgeo.rb

factory_store = RGeo::ActiveRecord::SpatialFactoryStore.instance
factory_store.register(RGeo::Geographic.spherical_factory(srid: 4326), geo_type: 'point', srid: 4326)