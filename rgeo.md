# RGeo Gem: A Step-by-Step Guide to Spatial Data in Rails

This document provides a comprehensive guide to integrating and using the RGeo gem for spatial data handling in a Rails application, with a particular focus on common pitfalls and their solutions, based on our recent debugging journey.

## 1. Introduction to RGeo

RGeo is a Ruby library that provides an object model for geospatial data. It implements the Open Geospatial Consortium (OGC) Simple Features Specification, allowing you to represent and manipulate geometric objects (points, lines, polygons) in Ruby. When combined with `rgeo-activerecord` and a spatial database adapter (like `activerecord-postgis-adapter`), it enables seamless integration of spatial data with ActiveRecord.

## 2. Installation

Add the following gems to your `Gemfile`:

```ruby
# Gemfile
gem 'rgeo'
gem 'rgeo-activerecord'
gem 'activerecord-postgis-adapter' # For PostgreSQL with PostGIS
```

Then, run `bundle install`:

```bash
bundle install
```

## 3. Database Setup (PostGIS)

RGeo works best with a spatial database extension like PostGIS for PostgreSQL.

### 3.1 Enable PostGIS Extension

Ensure the PostGIS extension is enabled in your database. You can do this via a migration:

```ruby
# db/migrate/YYYYMMDDHHMMSS_enable_postgis_extension.rb
class EnablePostgisExtension < ActiveRecord::Migration[7.0]
  def change
    enable_extension "postgis"
  end
end
```

Run the migration:

```bash
rails db:migrate
```

### 3.2 Define Spatial Columns in Migrations

When creating or modifying tables, define your spatial columns using `geometry` or `geography` types. For geographic coordinates (latitude/longitude), `geography` is generally preferred as it handles calculations on a sphere. Use `srid: 4326` for WGS84 (standard GPS coordinates).

```ruby
# Example: Adding a pickup_location to ride_requests table
# db/migrate/YYYYMMDDHHMMSS_add_pickup_location_to_ride_requests.rb
class AddPickupLocationToRideRequests < ActiveRecord::Migration[7.0]
  def change
    add_column :ride_requests, :pickup_location, :geography, geographic: true, srid: 4326
    add_index :ride_requests, :pickup_location, using: :gist # Add a spatial index for performance
  end
end

# Example: Changing an existing column to geography
# db/migrate/YYYYMMDDHHMMSS_change_location_to_geography_in_rides.rb
class ChangeLocationToGeographyInRides < ActiveRecord::Migration[7.0]
  def change
    change_column :rides, :location, :geography, geographic: true, srid: 4326
  end
end
```

Run the migrations:

```bash
rails db:migrate
```

## 4. RGeo Configuration in Rails

Proper RGeo configuration ensures ActiveRecord correctly interprets and stores spatial data.

### 4.1 `config/database.yml`

Ensure your database adapter is set to `postgis`:

```yaml
# config/database.yml
default: &default
  adapter: postgis
  encoding: unicode
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  host: localhost
  user: postgres
  password: postgres # Or your database password

development:
  <<: *default
  database: your_app_development

test:
  <<: *default
  database: your_app_test

production:
  <<: *default
  database: your_app_production
  username: <%= ENV["DATABASE_USERNAME"] %>
  password: <%= ENV["DATABASE_PASSWORD"] %>
```

### 4.2 `config/application.rb`

It's crucial to load `rgeo/active_record` early to ensure RGeo's extensions are available when models are loaded.

```ruby
# config/application.rb
require_relative "boot"

require "rails/all"
require "rgeo/active_record" # Add this line

# ... rest of your application.rb
```

### 4.3 RGeo Initializers (`config/initializers/rgeo_factory_config.rb`)

This file is where you configure the default RGeo factories for your spatial columns.

```ruby
# config/initializers/rgeo_factory_config.rb
RGeo::ActiveRecord::SpatialFactoryStore.instance.tap do |config|
  # By default, use the GEOS implementation for spatial columns.
  # config.default = RGeo::Geos.factory

  # Use a geographic implementation for point columns (SRID 4326 for WGS84).
  # This ensures that columns defined with `geographic: true` or `geography` type
  # are handled by the spherical factory.
  config.register(RGeo::Geographic.spherical_factory(srid: 4326), geo_type: "point")
end
```

**Important Note on Initializers:** Avoid redundant or conflicting RGeo initializers. If you have files like `rgeo_type_registration.rb` or `rgeo_types.rb` that manually register `ActiveRecord::Type` for RGeo, they might cause issues or be unnecessary. The `SpatialFactoryStore` and `rgeo/active_record` loading should handle most cases.

## 5. Using RGeo in Models

Once configured, ActiveRecord will automatically convert spatial data from the database into RGeo objects (e.g., `RGeo::Geographic::SphericalPointImpl`) when you read them, and convert RGeo objects into the appropriate database format when you save them.

```ruby
# app/models/ride_request.rb
class RideRequest < ApplicationRecord
  # ... other associations and validations

  # No explicit RGeo configuration needed here if initializers are set up correctly.
  # ActiveRecord will handle the type casting based on the database schema and RGeo initializers.

  # Example of accessing RGeo point attributes
  def get_latitude
    pickup_location.y if pickup_location.present?
  end

  def get_longitude
    pickup_location.x if pickup_location.present?
  end

  # Custom setter for spatial attributes (if needed for specific input formats)
  # This is useful if you receive WKT strings or hashes and want to convert them to RGeo objects
  # before ActiveRecord processes them.
  def pickup_location=(value)
    if value.is_a?(String) # If value is a WKT string
      super(RGeo::WKRep::WKTParser.new.parse(value))
    elsif value.is_a?(Hash) && value[:lat] && value[:lng] # If value is a hash with lat/lng
      factory = RGeo::Geographic.spherical_factory(srid: 4326)
      super(factory.point(value[:lng], value[:lat])) # RGeo expects (longitude, latitude)
    else
      super(value) # Let ActiveRecord handle RGeo objects directly
    end
  end
end
```

## 6. Using RGeo in GraphQL Mutations/Queries

When working with GraphQL, you need to ensure consistency between your GraphQL input types, mutation resolvers, and how RGeo objects are handled.

### 6.1 GraphQL Input Types

Define input types that match the expected structure for spatial data (e.g., `lat` and `lng` for points).

```ruby
# app/graphql/types/geometry_input_type.rb
module Types
  class GeometryInputType < Types::BaseInputObject
    argument :lat, Float, required: true
    argument :lng, Float, required: true
  end
end
```

### 6.2 GraphQL Mutation Resolvers

In your mutation resolvers, convert the incoming GraphQL input into an RGeo object before passing it to the ActiveRecord model.

```ruby
# app/graphql/mutations/create_ride_request.rb
module Mutations
  class CreateRideRequest < BaseMutation
    # ... other arguments
    argument :pickup_location, Types::GeometryInputType, required: true

    def resolve(pickup_time:, destination:, max_passengers:, proposed_fare:, require_verified_passengers:, pickup_location:)
      # ... authentication and validation

      # Convert incoming GraphQL input (hash with lat/lng) to RGeo point
      factory = RGeo::Geographic.spherical_factory(srid: 4326)
      pickup_point = factory.point(pickup_location[:lng], pickup_location[:lat]) # RGeo expects (longitude, latitude)

      ride_request = RideRequest.new(
        # ... other attributes
        pickup_location: pickup_point # Pass the RGeo point directly
      )

      if ride_request.save
        { ride_request: ride_request, errors: [] }
      else
        { ride_request: nil, errors: ride_request.errors.full_messages }
      end
    end
  end
end
```

### 6.3 GraphQL Output Types

When exposing spatial data in your GraphQL output, convert the RGeo object back into a serializable format (e.g., a hash with `latitude` and `longitude`).

```ruby
# app/graphql/types/geometry_type.rb
module Types
  class GeometryType < Types::BaseObject
    field :latitude, Float, null: false
    field :longitude, Float, null: false
  end
end

# app/graphql/types/ride_request_type.rb
module Types
  class RideRequestType < Types::BaseObject
    # ... other fields
    field :pickup_location, Types::GeometryType, null: true

    def pickup_location
      return unless object.pickup_location
      # Convert RGeo point to a hash for GraphQL output
      { latitude: object.pickup_location.y, longitude: object.pickup_location.x }
    end
  end
end
```

## 7. Common Errors & Fixes (Our Journey)

Here are some of the specific errors we encountered and how they were resolved:

### 7.1 `TypeError: can't quote RGeo::Geographic::SphericalPointImpl`

*   **Cause:** This error occurs when ActiveRecord tries to directly quote an `RGeo::Geographic::SphericalPointImpl` object for database storage, but the database adapter isn't properly configured to handle it, or the object is being passed in a context where ActiveRecord expects a simple string or numeric type.
*   **Our Fix:** We implemented a custom setter for `pickup_location` in `app/models/ride_request.rb`. This setter explicitly converts the incoming RGeo point object into its WKT (Well-Known Text) string representation before passing it to ActiveRecord's default setter. This ensures ActiveRecord receives a string it can easily quote, and the `activerecord-postgis-adapter` then correctly interprets the WKT string for storage.

    ```ruby
    # app/models/ride_request.rb
    class RideRequest < ApplicationRecord
      # ...
      def pickup_location=(value)
        if value.is_a?(RGeo::Feature::Point)
          super(value.as_text) # Convert RGeo point to WKT string
        else
          super(value) # Handle other cases (e.g., WKT string directly)
        end
      end
      # ...
    end
    ```

### 7.2 `NoMethodError: undefined method 'spherical_factory_generator' for module RGeo::Geographic`

*   **Cause:** This error typically arises when deprecated RGeo methods (like `spherical_factory_generator` or `set_rgeo_factory_for_column`) are used in models, or when the `rgeo-activerecord` gem's extensions are not loaded early enough in the Rails boot process. Rails initializers run *after* models are loaded by default, leading to this `NoMethodError` if models try to configure RGeo before it's fully initialized.
*   **Our Fix:**
    1.  **Removed deprecated calls from models:** We removed `self.rgeo_factory_generator` and `set_rgeo_factory_for_column` from `app/models/ride_request.rb`.
    2.  **Ensured early loading of `rgeo/active_record`:** We added `require "rgeo/active_record"` to `config/application.rb` to guarantee that RGeo's ActiveRecord extensions are loaded before any models that might rely on them.

### 7.3 `NameError: uninitialized constant RGeo::ActiveRecord::SpatialType`

*   **Cause:** This error occurs when `RGeo::ActiveRecord::SpatialType` is referenced (e.g., via `attribute :column, RGeo::ActiveRecord::SpatialType.new(...)`) before the `rgeo-activerecord` gem has fully loaded and defined this constant. This is another manifestation of Rails' loading order issues.
*   **Our Fix:** We reverted the use of `attribute :pickup_location, RGeo::ActiveRecord::SpatialType.new(...)` in `app/models/ride_request.rb`. Instead, we relied on the custom setter (as described in 7.1) to handle the conversion of RGeo objects to WKT strings. This approach bypasses the need for `attribute` to directly handle the RGeo type, thus avoiding the `NameError`. The combination of the custom setter and the `rgeo_factory_config.rb` initializer is sufficient for proper spatial data handling.

### 7.4 Input/Output Mismatches (e.g., `lat`/`lng` vs. `latitude`/`longitude`)

*   **Cause:** Inconsistencies between the field names used in GraphQL input types (e.g., `lat`, `lng`), the mutation resolvers that process these inputs, and the GraphQL output types that expose the data.
*   **Our Fix:** We ensured strict consistency:
    *   **GraphQL Input Type (`Types::GeometryInputType`):** Defined with `lat` and `lng` arguments.
    *   **Mutation Resolver (`CreateRideRequest`):** Accessed `pickup_location[:lat]` and `pickup_location[:lng]` to create the RGeo point.
    *   **GraphQL Output Type (`Types::GeometryType` and `RideRequestType`):** Defined `latitude` and `longitude` fields, and converted the RGeo point's `x` (longitude) and `y` (latitude) attributes to match.
    *   **Curl Commands:** Ensured the JSON payload matched the GraphQL input type's field names (`lat`, `lng`).

## Conclusion

While RGeo is a powerful tool for spatial data in Rails, careful attention to gem installation, database configuration, Rails loading order, and consistent data handling across your application (especially in GraphQL) is crucial. By understanding and systematically addressing these common issues, you can successfully leverage RGeo for your location-aware features.
