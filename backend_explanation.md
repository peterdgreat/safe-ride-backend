SafeRideNG is a crucial ride-hailing MVP designed for the Nigerian context, where ride scheduling incorporates unique safety features to mitigate kidnapping risks. The backend, built on Ruby on Rails, leverages a robust set of technologies to deliver a secure, scalable, and user-friendly platform. This explanation details the architectural choices, code implementations, and design decisions that underpin SafeRideNG's backend.

### Backend Architecture Overview

The SafeRideNG backend is a Ruby on Rails API application with a GraphQL interface. It utilizes PostgreSQL with PostGIS for spatial data, Devise for user authentication, Pundit for granular authorization, ActionCable for real-time communication, and Sidekiq for asynchronous job processing. Africa's Talking is integrated for SMS and WhatsApp notifications, crucial for emergency contacts and USSD support.

### Code Structure

The backend's codebase is organized logically, adhering to Rails conventions while integrating GraphQL and background processing components.

#### Models

The core of the application's data layer is defined by its ActiveRecord models, each representing a key entity:

*   **`User`**: The central authentication entity, managed by Devise. It includes basic user information (`email`, `phone_number`, `first_name`, `last_name`, `is_verified`) and a `jti` (JWT ID) for token revocation.
    ```ruby
    # app/models/user.rb
    class User < ApplicationRecord
      attr_accessor :login
      devise :database_authenticatable, :registerable,
             :recoverable, :rememberable, :jwt_authenticatable, jwt_revocation_strategy: self

      has_one :profile, dependent: :destroy
      has_many :emergency_contacts, dependent: :destroy
      has_one :driver, dependent: :destroy # A user can be a driver

      def self.find_for_database_authentication(warden_conditions)
        conditions = warden_conditions.dup
        if login = conditions.delete(:login)
          where(conditions.to_h).where(["lower(email) = :value OR lower(phone_number) = :value", { value: login.downcase }]).first
        elsif conditions.has_key?(:email) || conditions.has_key?(:phone_number)
          where(conditions.to_h).first
        end
      end

      include Devise::JWT::RevocationStrategies::JTIMatcher

      def generate_jwt
        JWT.encode({ jti: self.jti, sub: self.id, scp: "user", aud: nil, exp: (Time.now + 1.hour).to_i }, Rails.application.credentials.devise_jwt_secret_key!)
      end
    end
    ```
*   **`Profile`**: Stores additional customer-specific details (`date_of_birth`, `gender`, `profile_picture_url`), linked to a `User` via `belongs_to :user`.
*   **`EmergencyContact`**: Represents a mandatory WhatsApp contact for a user, with `name` and `whatsapp_number`. Linked to `User`.
*   **`Driver`**: Represents a driver's specific details (`license_plate`, `car_model`, `car_color`), linked to a `User`. This model differentiates a user as a driver.
*   **`RideRequest`**: Details a scheduled ride request (`passenger_id`, `pickup_time`, `destination`, `max_passengers`, `proposed_fare`, `require_verified_passengers`, `pickup_location` (spatial data)).
*   **`Ride`**: Represents an active ride, linking a `RideRequest` to a `Driver` (which is a `User` in this schema) and including spatial `location` data.
    ```ruby
    # app/models/ride.rb
    class Ride < ApplicationRecord
      belongs_to :driver, class_name: 'User' # Driver is a User
      belongs_to :ride_request
      has_many :ride_passengers
      has_many :passengers, through: :ride_passengers, source: :passenger

      # Custom setter for location to handle RGeo objects
      def location=(value)
        if value.is_a?(String) # If value is a WKT string
          super(RGeo::WKRep::WKTParser.new.parse(value))
        elsif value.is_a?(Hash) && value[:lat] && value[:lng] # If value is a hash with lat/lng
          factory = RGeo::Geographic.spherical_factory(srid: 4326)
          super(factory.point(value[:lng], value[:lat])) # RGeo expects (longitude, latitude)
        else
          super(value) # Let ActiveRecord handle RGeo objects directly
        end
      end

      after_save do
        # Trigger real-time updates via ActionCable
        RideHailingSchema.subscriptions.trigger(
          :ride_updated,
          { ride_id: id },
          self
        )
      end
    end
    ```
*   **`Rating`**: Stores ride ratings (`ride_id`, `ratee_id`, `score`), linked to `Ride` and `User` (ratee).

#### GraphQL

The GraphQL layer provides a strongly typed API for frontend and external service interactions.

*   **Types (`app/graphql/types/`)**: Define the structure of data exposed through the API. Examples include `ProfileType`, `RideType`, `DriverType`, `UserType`, `EmergencyContactType`, `RideRequestType`, `RatingType`. Input types like `CreateUserInput`, `LoginInput`, `CreateEmergencyContactInput`, `CreateDriverProfileInput`, `CreateRideInput`, `CreateScheduledRideRequestInput`, `JoinRideInput`, `SubmitRatingInput`, `SendEmergencyAlertInput` are also defined here.
*   **Queries (`app/graphql/types/query_type.rb`)**: Define entry points for fetching data.
    ```ruby
    # app/graphql/types/query_type.rb
    module Types
      class QueryType < Types::BaseObject
        include Pundit::Authorization # For policy_scope and authorize

        field :driver, Types::DriverType, null: true do
          argument :id, ID, required: true
        end

        def driver(id:)
          driver = Driver.find_by(id: id)
          return nil unless driver # Handle case where driver is not found
          # Authorize the current user to view this driver profile
          Pundit.authorize(context[:current_user], driver, :show?)
          driver
        end

        field :profile, Types::ProfileType, null: true

        def profile
          profile = context[:current_user]&.profile
          return nil unless profile # Handle case where profile is not found
          # Authorize the current user to view their own profile
          Pundit.authorize(context[:current_user], profile, :show?)
          profile
        end

        field :nearby_rides, [Types::RideType], null: false do
          argument :lat, Float, required: true
          argument :lng, Float, required: true
        end

        def nearby_rides(lat:, lng:)
          factory = RGeo::Geographic.spherical_factory(srid: 4326)
          point = factory.point(lng, lat)
          # Use policy_scope for authorization on the collection
          # Ensure SRID consistency in PostGIS query
          Pundit.policy_scope(context[:current_user], Ride.where("ST_DWithin(location::geometry(Point, 4326), ST_GeomFromText(?, 4326), 5000)", point.as_text))
        end

        field :scheduled_ride_requests, [Types::RideRequestType], null: false

        def scheduled_ride_requests
          # Authorize the current user to view ride requests
          Pundit.policy_scope(context[:current_user], RideRequest)
        end
      end
    end
    ```
*   **Mutations (`app/graphql/mutations/`)**: Define operations that modify data. Each mutation typically has its own file (e.g., `create_emergency_contact.rb`, `create_scheduled_ride_request.rb`, `join_ride.rb`, `submit_rating.rb`, `send_emergency_alert.rb`, `create_driver_profile.rb`, `create_ride.rb`).
    ```ruby
    # app/graphql/mutations/create_emergency_contact.rb
    module Mutations
      class CreateEmergencyContact < GraphQL::Schema::Mutation
        argument :input, Types::CreateEmergencyContactInput, required: true

        field :emergency_contact, Types::EmergencyContactType, null: true
        field :errors, [String], null: false

        def resolve(input:)
          emergency_contact = EmergencyContact.new(input.to_h)
          emergency_contact.user = context[:current_user] # Associate with current user
          # Authorize the current user to create an emergency contact
          authorize! :create, emergency_contact

          if emergency_contact.save
            { emergency_contact: emergency_contact, errors: [] }
          else
            { emergency_contact: nil, errors: emergency_contact.errors.full_messages }
          end
        end

        private
        # Private helper method for authorization (can be in BaseMutation or duplicated)
        def authorize!(action, subject)
          unless Pundit.policy(context[:current_user], subject).public_send("#{action}")
            raise GraphQL::ExecutionError, 'Not authorized'
          end
        end
      end
    end
    ```
    ```ruby
    # app/graphql/mutations/create_ride.rb
    module Mutations
      class CreateRide < GraphQL::Schema::Mutation
        argument :input, Types::CreateRideInput, required: true

        field :ride, Types::RideType, null: true
        field :errors, [String], null: false

        def resolve(input:)
          ride_request = RideRequest.find_by(id: input[:ride_request_id])
          driver_profile = Driver.find_by(id: input[:driver_id])
          driver_user = driver_profile.user if driver_profile # Get the User associated with the Driver profile

          unless ride_request && driver_user
            return { ride: nil, errors: ["Ride request or driver not found"] }
          end

          ride = Ride.new(
            ride_request: ride_request,
            driver: driver_user, # Pass the User object for the driver association
            location: input[:location] # Pass WKT string, RGeo handles parsing
          )

          # Authorize the driver to create a ride
          authorize! :create, ride

          if ride.save
            { ride: ride, errors: [] }
          else
            { ride: nil, errors: ride.errors.full_messages }
          end
        end

        private
        def authorize!(action, subject)
          unless Pundit.policy(context[:current_user], subject).public_send("#{action}")
            raise GraphQL::ExecutionError, 'Not authorized'
          end
        end
      end
    end
    ```
*   **Subscriptions (`app/graphql/types/subscription_type.rb`)**: Define real-time data streams. `rideUpdated` is a key subscription for real-time ride status changes.

#### Jobs

Sidekiq is used for background job processing, ensuring that long-running or non-critical tasks don't block the main request-response cycle.

*   **`SendWhatsappJob`**: Handles sending WhatsApp messages via Africa's Talking.
*   **`SendSmsJob`**: Handles sending SMS messages via Africa's Talking.

#### Controllers

*   **`GraphqlController`**: The main entry point for all GraphQL API requests (`/graphql`). It handles parsing requests, executing queries/mutations, and rendering responses. It also manages `current_user` context for authorization.
*   **`UssdController`**: A dedicated controller for handling USSD requests. It parses USSD input, interacts with the application logic (e.g., creating ride requests, adding contacts), and generates USSD responses.

### Key Features and Implementation Details

#### Emergency Contact Validation before Ride Scheduling

Before a user can schedule a ride, the backend enforces that at least one WhatsApp emergency contact is registered. This is implemented within the `CreateScheduledRideRequest` mutation.

```ruby
# app/graphql/mutations/create_scheduled_ride_request.rb (snippet)
module Mutations
  class CreateScheduledRideRequest < GraphQL::Schema::Mutation
    # ... arguments and fields ...

    def resolve(input:)
      # Check for emergency contact
      unless context[:current_user].emergency_contacts.exists?
        # Custom error message in Pidgin for better user experience
        return { ride_request: nil, errors: ["Add emergency contact fess!"] }
      end

      ride_request = RideRequest.new(input.to_h)
      ride_request.passenger = context[:current_user]
      authorize! :create, ride_request # Pundit authorization

      if ride_request.save
        { ride_request: ride_request, errors: [] }
      else
        { ride_request: nil, errors: ride_request.errors.full_messages }
      end
    end
    # ... private authorize! method ...
  end
end
```

#### PostGIS for Matching Rides within 5km

PostGIS, the spatial extension for PostgreSQL, is used for efficient geographic queries. The `nearby_rides` query in `QueryType` demonstrates this.

```ruby
# app/graphql/types/query_type.rb (nearby_rides resolver snippet)
field :nearby_rides, [Types::RideType], null: false do
  argument :lat, Float, required: true
  argument :lng, Float, required: true
end

def nearby_rides(lat:, lng:)
  factory = RGeo::Geographic.spherical_factory(srid: 4326)
  point = factory.point(lng, lat) # Create an RGeo point object

  # Use ST_DWithin for distance query.
  # Explicitly cast location to geometry(Point, 4326) for SRID consistency.
  # point.as_text converts the RGeo point to WKT for PostgreSQL.
  Pundit.policy_scope(context[:current_user], Ride.where("ST_DWithin(location::geometry(Point, 4326), ST_GeomFromText(?, 4326), 5000)", point.as_text))
end
```

The `location` column in the `rides` table is defined as a `geography(Point, 4326)` type in the migration, ensuring it stores geographic points with the WGS 84 spatial reference system (SRID 4326). A GIST index is added to this column for optimized spatial queries.

#### Africa's Talking for WhatsApp/SMS Notifications

Africa's Talking is integrated via Sidekiq jobs to send asynchronous notifications.

```ruby
# app/jobs/send_whatsapp_job.rb
class SendWhatsappJob < ApplicationJob
  queue_as :default

  def perform(recipient, message)
    # Africa's Talking API integration
    # Replace with actual API calls to Africa's Talking
    Rails.logger.info "Sending WhatsApp to #{recipient}: #{message}"
    # AfricaTalking.send_whatsapp(recipient, message)
  end
end

# app/jobs/send_sms_job.rb
class SendSmsJob < ApplicationJob
  queue_as :default

  def perform(recipient, message)
    # Africa's Talking API integration
    # Replace with actual API calls to Africa's Talking
    Rails.logger.info "Sending SMS to #{recipient}: #{message}"
    # AfricaTalking.send_sms(recipient, message)
  end
end
```

Example usage in a model or service:

```ruby
# app/models/ride.rb (example of notification trigger)
# ...
after_save do
  if saved_change_to_status? && status == 'started'
    # Example: Notify emergency contacts when ride starts
    ride_request.passenger.emergency_contacts.each do |contact|
      message = "Peter just left Kubwa, Abj heading to Gwarinpa, estimated 30 mins journey. Track: [link]"
      SendWhatsappJob.perform_later(contact.whatsapp_number, message)
    end
  end
end
# ...
```

#### ActionCable for Real-time Ride Updates

ActionCable provides WebSocket-based real-time communication. The `rideUpdated` subscription allows clients to receive live updates on ride status changes.

```ruby
# app/graphql/types/subscription_type.rb
module Types
  class SubscriptionType < Types::BaseObject
    field :ride_updated, Types::RideType, null: false do
      argument :ride_id, ID, required: true
    end

    def ride_updated(ride_id:)
      # This method is called when a client subscribes.
      # The actual data is pushed by the Ride model's after_save callback.
      Ride.find(ride_id)
    end
  end
end

# app/models/ride.rb (after_save callback snippet)
# ...
after_save do
  RideHailingSchema.subscriptions.trigger(
    :ride_updated,
    { ride_id: id }, # Arguments to match the subscription field
    self # The updated Ride object
  )
end
# ...
```

#### USSD Support for Scheduling Rides and Adding Contacts

The `UssdController` handles incoming USSD requests, which are typically HTTP POST requests from the Africa's Talking gateway.

```ruby
# app/controllers/ussd_controller.rb (conceptual)
class UssdController < ApplicationController
  skip_before_action :verify_authenticity_token # USSD requests don't have CSRF tokens

  def handle_request
    session_id = params[:sessionId]
    service_code = params[:serviceCode]
    phone_number = params[:phoneNumber]
    text = params[:text] # User's input

    response = ""

    if text == ""
      # Initial request
      response = "CON Welcome to SafeRideNG!\n1. Request a Ride\n2. Add Emergency Contact"
    elsif text == "1"
      # User selected Request a Ride
      response = "CON Enter pickup time (YYYY-MM-DD HH:MM) and destination (e.g., 2025-07-23 10:00, Kubwa to Gwarinpa)"
    elsif text.start_with?("1*")
      # User provided ride details
      _text, pickup_time_str, destination_str = text.split('*')
      # Process ride request (e.g., create RideRequest, notify drivers)
      # This would involve calling a service object or a background job
      response = "END Your ride request has been submitted!"
    elsif text == "2"
      # User selected Add Emergency Contact
      response = "CON Enter contact name and WhatsApp number (e.g., John, +2348012345678)"
    elsif text.start_with?("2*")
      # User provided contact details
      _text, name, whatsapp_number = text.split('*')
      # Create EmergencyContact for the user
      # This would involve finding the user by phone_number and creating the contact
      response = "END Emergency contact added successfully!"
    else
      response = "END Invalid input. Please try again."
    end

    render plain: response, content_type: "text/plain"
  end
end
```

### Design Decisions

#### Why use UUIDs for Primary Keys?

UUIDs (Universally Unique Identifiers) are used for primary keys instead of auto-incrementing integers for several reasons:

*   **Distributed Systems:** UUIDs can be generated independently across different services or database instances without coordination, preventing ID collisions in a distributed architecture.
*   **Security:** Sequential integer IDs can be easily guessed, making it easier for malicious actors to enumerate records. UUIDs are difficult to guess, adding a layer of obscurity.
*   **Data Merging:** When merging data from different sources (e.g., offline data, different regions), UUIDs prevent ID conflicts.
*   **Client-Side Generation:** In some cases, UUIDs can be generated on the client-side, reducing latency for record creation.

#### Why PostGIS for Location Matching? How is the 5km radius implemented?

*   **Geospatial Capabilities:** PostGIS extends PostgreSQL with powerful geospatial functions, making it ideal for location-based services like ride-hailing. It allows storing, querying, and analyzing geographic objects efficiently.
*   **`ST_DWithin`:** This PostGIS function is used to find geometries within a specified distance of another geometry.
    *   `ST_DWithin(geometry1, geometry2, distance_in_meters)`: It returns true if `geometry1` is within `distance_in_meters` of `geometry2`.
*   **5km Radius Implementation:** In the `nearby_rides` query, `ST_DWithin(location::geography(Point, 4326), ST_GeomFromText(?, 4326), 5000)` is used.
    *   `location::geography(Point, 4326)`: Casts the `location` column (which is a PostGIS geography) to a specific type with SRID 4326, ensuring consistency.
    *   `ST_GeomFromText(?, 4326)`: Converts the Well-Known Text (WKT) representation of the query point (e.g., "POINT(-118.2437 34.0522)") into a PostGIS geometry object with SRID 4326.
    *   `5000`: Represents 5000 meters (5 kilometers).
*   **Spatial Indexing:** A GIST index is applied to the `location` column in the `rides` table (`add_index :rides, :location, using: :gist`). This index significantly speeds up spatial queries like `ST_DWithin` by allowing the database to quickly narrow down the search area.

#### Why GraphQL over REST? Why ActionCable for Subscriptions?

*   **GraphQL over REST:**
    *   **Single Endpoint:** All interactions happen through a single `/graphql` endpoint, simplifying API management.
    *   **Reduced Over/Under-fetching:** Clients request exactly the data they need, preventing over-fetching (receiving too much data) and under-fetching (needing multiple requests for related data). This is crucial for mobile applications with limited bandwidth.
    *   **Strong Typing and Introspection:** The GraphQL schema is strongly typed, providing clear data contracts and enabling powerful introspection tools (like GraphiQL) for API exploration and auto-completion.
    *   **Versionless API:** Changes to the data model can be introduced without breaking existing clients, as clients only query for the fields they need.
*   **ActionCable for Subscriptions:**
    *   **Real-time Updates:** ActionCable provides a WebSocket-based solution for real-time communication, which is essential for features like live ride tracking, status updates (e.g., "driver arrived," "ride started"), and emergency alerts.
    *   **Integrated with Rails:** As part of the Rails ecosystem, ActionCable integrates seamlessly with ActiveRecord callbacks and the existing application logic, making it easy to trigger and broadcast updates.
    *   **Scalability:** ActionCable can be scaled horizontally with Redis as a backend, handling a large number of concurrent WebSocket connections.

#### Why Sidekiq for Background Jobs? How does Africa's Talking integrate with WhatsApp/SMS?

*   **Asynchronous Processing:** Sidekiq is a robust background processing framework for Ruby. It's used for tasks that don't need to be completed immediately or that might take a long time, preventing them from blocking the main web server.
    *   **Examples:** Sending WhatsApp/SMS notifications, processing ride status changes, generating reports, or any other computationally intensive tasks.
*   **Reliability:** Sidekiq uses Redis to store job queues, ensuring that jobs are not lost even if the application crashes. It also supports retries and error handling.
*   **Africa's Talking Integration:**
    *   Africa's Talking provides APIs for sending SMS and WhatsApp messages.
    *   The integration involves making HTTP requests to their API endpoints with the message content, recipient, and sender ID.
    *   These API calls are placed within Sidekiq jobs (`SendWhatsappJob`, `SendSmsJob`) because network requests can be slow and unreliable. By putting them in background jobs, the main application remains responsive, and failed deliveries can be retried.

#### How do multilingual SMS/WhatsApp messages and Pidgin errors enhance lovability?

*   **Localization (L10n):** Supporting multiple languages (including local dialects like Pidgin) makes the application more accessible and user-friendly for a diverse Nigerian audience. It shows cultural sensitivity and improves communication clarity.
*   **Pidgin Errors:** Providing error messages in Pidgin (e.g., "Add emergency contact fess!") makes the application feel more native and relatable to users who commonly speak Pidgin. This can reduce frustration and improve the overall user experience by making errors easier to understand and act upon. This is a key aspect of "lovability" in the Nigerian context.

### Safety

SafeRideNG's core mission is safety, and the backend implements several features to achieve this:

*   **Verification Checks (`is_verified`):**
    *   The `User` model has an `is_verified` flag. This flag is crucial for ensuring that only legitimate and verified individuals can participate in rides.
    *   While the current MVP might not detail the verification process (e.g., OTP, biometric), the backend is designed to enforce this check before critical actions (e.g., joining a ride, becoming a driver).
    *   Pundit policies (`RidePolicy`, `DriverPolicy`) can be extended to check `user.is_verified` before allowing certain actions.
*   **Emergency Contact Notifications:**
    *   The mandatory emergency contact (`EmergencyContact` model) is a primary safety feature.
    *   Before scheduling a ride, the system ensures at least one contact is registered.
    *   Upon ride start and completion, automated WhatsApp/SMS notifications are sent to these contacts, providing ride details and a tracking link. This keeps trusted individuals informed of the user's journey progress.
*   **Real-time Monitoring:**
    *   ActionCable subscriptions (`rideUpdated`) enable real-time tracking of ride status. This allows both the passenger and potentially a control center to monitor the ride's progress.
    *   In an emergency, this real-time data can be crucial for rapid response.
*   **Verified Users Only:**
    *   Pundit policies are used to ensure that only authorized and potentially verified users can perform specific actions.
    *   For instance, the `RidePolicy` ensures that only a `User` with an associated `Driver` profile can create a ride. Similarly, policies can be implemented to ensure only verified passengers can join rides or that only the ride's actual passenger can submit a rating.

### Architecture Diagram (Draw.io XML)

```xml
<mxfile host="app.diagrams.net" modified="2023-10-27T10:00:00.000Z" agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0.0.0 Safari/537.36" etag="YOUR_ETAG_HERE" version="22.0.8" type="device">
  <diagram id="SafeRideNG_Backend_Architecture" name="Page-1">
    <mxGraphModel dx="1434" dy="806" grid="1" gridSize="10" guides="1" tooltips="1" connect="1" arrows="1" fold="1" page="1" pageEnabled="1" pageScale="1" pageWidth="850" pageHeight="1100" math="0" shadow="0">
      <root>
        <mxCell id="0" />
        <mxCell id="1" parent="0" />
        <!-- Rails API -->
        <mxCell id="2" value="Rails API Backend" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#dae8fc;strokeColor=#6c8ebf;" parent="1" vertex="1">
          <mxGeometry x="300" y="150" width="200" height="80" as="geometry" />
        </mxCell>
        <mxCell id="3" value="GraphQL Endpoint (/graphql)" style="rounded=0;whiteSpace=wrap;html=1;fillColor=#d5e8d4;strokeColor=#82b366;" parent="2" vertex="1">
          <mxGeometry x="20" y="20" width="160" height="30" as="geometry" />
        </mxCell>
        <mxCell id="4" value="ActionCable (WebSocket)" style="rounded=0;whiteSpace=wrap;html=1;fillColor=#d5e8d4;strokeColor=#82b366;" parent="2" vertex="1">
          <mxGeometry x="20" y="55" width="160" height="30" as="geometry" />
        </mxCell>
        <mxCell id="5" value="Sidekiq" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#fff2cc;strokeColor=#d6b656;" parent="1" vertex="1">
          <mxGeometry x="350" y="300" width="100" height="50" as="geometry" />
        </mxCell>

        <!-- Database -->
        <mxCell id="6" value="PostgreSQL Database" style="shape=cylinder;whiteSpace=wrap;html=1;backgroundOutline=1;fillColor=#e1d5e7;strokeColor=#9673a6;" parent="1" vertex="1">
          <mxGeometry x="600" y="150" width="80" height="100" as="geometry" />
        </mxCell>
        <mxCell id="7" value="PostGIS Extension" style="text;html=1;align=center;verticalAlign=middle;resizable=0;points=[];autosize=1;" parent="6" vertex="1">
          <mxGeometry x="0" y="70" width="80" height="20" as="geometry" />
        </mxCell>
        <mxCell id="8" value="Tables: users, drivers, rides, etc." style="text;html=1;align=center;verticalAlign=middle;resizable=0;points=[];autosize=1;" parent="6" vertex="1">
          <mxGeometry x="0" y="0" width="80" height="20" as="geometry" />
        </mxCell>

        <!-- External Services -->
        <mxCell id="9" value="Africa's Talking" style="shape=cloud;whiteSpace=wrap;html=1;fillColor=#f8cecc;strokeColor=#b85450;" parent="1" vertex="1">
          <mxGeometry x="600" y="300" width="120" height="80" as="geometry" />
        </mxCell>
        <mxCell id="10" value="WhatsApp / SMS" style="text;html=1;align=center;verticalAlign=middle;resizable=0;points=[];autosize=1;" parent="9" vertex="1">
          <mxGeometry x="0" y="50" width="120" height="20" as="geometry" />
        </mxCell>
        <mxCell id="11" value="Google Maps API (Optional)" style="shape=cloud;whiteSpace=wrap;html=1;fillColor=#f8cecc;strokeColor=#b85450;" parent="1" vertex="1">
          <mxGeometry x="600" y="450" width="120" height="80" as="geometry" />
        </mxCell>
        <mxCell id="12" value="Estimated Duration" style="text;html=1;align=center;verticalAlign=middle;resizable=0;points=[];autosize=1;" parent="11" vertex="1">
          <mxGeometry x="0" y="50" width="120" height="20" as="geometry" />
        </mxCell>

        <!-- Frontend -->
        <mxCell id="13" value="Frontend (Web/Mobile App)" style="shape=card;whiteSpace=wrap;html=1;fillColor=#e0e0e0;strokeColor=#999999;" parent="1" vertex="1">
          <mxGeometry x="50" y="150" width="150" height="80" as="geometry" />
        </mxCell>

        <!-- Data Flows -->
        <mxCell id="14" value="GraphQL Requests" style="endArrow=classic;html=1;rounded=0;entryX=0;entryY=0.5;entryDx=0;entryDy=0;exitX=1;exitY=0.5;exitDx=0;exitDy=0;" parent="1" source="13" target="3" edge="1">
          <mxGeometry width="50" height="50" relative="1" as="geometry">
            <mxPoint x="200" y="185" as="sourcePoint" />
            <mxPoint x="300" y="185" as="targetPoint" />
          </mxGeometry>
        </mxCell>
        <mxCell id="15" value="WebSocket Updates" style="endArrow=classic;html=1;rounded=0;entryX=0;entryY=0.5;entryDx=0;entryDy=0;exitX=1;exitY=0.5;exitDx=0;exitDy=0;" parent="1" source="13" target="4" edge="1">
          <mxGeometry width="50" height="50" relative="1" as="geometry">
            <mxPoint x="200" y="210" as="sourcePoint" />
            <mxPoint x="300" y="210" as="targetPoint" />
          </mxGeometry>
        </mxCell>
        <mxCell id="16" value="DB Operations" style="endArrow=classic;html=1;rounded=0;entryX=0;entryY=0.5;entryDx=0;entryDy=0;exitX=1;exitY=0.5;exitDx=0;exitDy=0;" parent="1" source="2" target="6" edge="1">
          <mxGeometry width="50" height="50" relative="1" as="geometry">
            <mxPoint x="500" y="190" as="sourcePoint" />
            <mxPoint x="600" y="190" as="targetPoint" />
          </mxGeometry>
        </mxCell>
        <mxCell id="17" value="Background Jobs" style="endArrow=classic;html=1;rounded=0;entryX=0.5;entryY=0;entryDx=0;entryDy=0;exitX=0.5;exitY=1;exitDx=0;exitDy=0;" parent="1" source="2" target="5" edge="1">
          <mxGeometry width="50" height="50" relative="1" as="geometry">
            <mxPoint x="400" y="230" as="sourcePoint" />
            <mxPoint x="400" y="300" as="targetPoint" />
          </mxGeometry>
        </mxCell>
        <mxCell id="18" value="API Calls" style="endArrow=classic;html=1;rounded=0;entryX=0;entryY=0.5;entryDx=0;entryDy=0;exitX=1;exitY=0.5;exitDx=0;exitDy=0;" parent="1" source="5" target="9" edge="1">
          <mxGeometry width="50" height="50" relative="1" as="geometry">
            <mxPoint x="450" y="325" as="sourcePoint" />
            <mxPoint x="600" y="325" as="targetPoint" />
          </mxGeometry>
        </mxCell>
        <mxCell id="19" value="API Calls" style="endArrow=classic;html=1;rounded=0;entryX=0;entryY=0.5;entryDx=0;entryDy=0;exitX=1;exitY=0.5;exitDx=0;exitDy=0;" parent="1" source="2" target="11" edge="1">
          <mxGeometry width="50" height="50" relative="1" as="geometry">
            <mxPoint x="500" y="480" as="sourcePoint" />
            <mxPoint x="600" y="480" as="targetPoint" />
            <Array as="points">
              <mxPoint x="550" y="480" />
            </Array>
          </mxGeometry>
        </mxCell>
        <mxCell id="20" value="USSD Requests" style="endArrow=classic;html=1;rounded=0;entryX=0.5;entryY=0;entryDx=0;entryDy=0;exitX=0.5;exitY=1;exitDx=0;exitDy=0;" parent="1" source="9" target="2" edge="1">
          <mxGeometry width="50" height="50" relative="1" as="geometry">
            <mxPoint x="660" y="380" as="sourcePoint" />
            <mxPoint x="400" y="230" as="targetPoint" />
            <Array as="points">
              <mxPoint x="660" y="260" />
              <mxPoint x="400" y="260" />
            </Array>
          </mxGeometry>
        </mxCell>
      </root>
    </mxGraphModel>
  </diagram>
</mxfile>
```