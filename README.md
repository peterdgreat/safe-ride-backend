# SafeRideNG Backend

This repository contains the backend for SafeRideNG, a ride-hailing MVP designed to address kidnapping risks in Nigeria through features like ride scheduling, passenger verification, and emergency contacts.

## Table of Contents

- [System Requirements](#system-requirements)
- [Setup](#setup)
  - [Database Configuration](#database-configuration)
  - [Environment Variables](#environment-variables)
  - [Migrations](#migrations)
- [Running the Application](#running-the-application)
- [Testing the API with cURL](#testing-the-api-with-curl)
  - [GraphQL Endpoint](#graphql-endpoint)
  - [Authentication (Login)](#authentication-login)
  - [Creating a User](#creating-a-user)
  - [Creating a Driver Profile](#creating-a-driver-profile)
  - [Creating an Emergency Contact](#creating-an-emergency-contact)
  - [Creating a Scheduled Ride Request](#creating-a-scheduled-ride-request)
  - [Creating a Ride (Driver Accepts)](#creating-a-ride-driver-accepts)
  - [Joining a Ride](#joining-a-ride)
  - [Submitting a Rating](#submitting-a-rating)
  - [Creating a Ride Share Link](#creating-a-ride-share-link)
  - [Sending an Emergency Alert](#sending-an-emergency-alert)
  - [Querying Driver Information](#querying-driver-information)
  - [Querying User Profile](#querying-user-profile)
  - [Querying Nearby Rides](#querying-nearby-rides)
  - [Querying Scheduled Ride Requests](#querying-scheduled-ride-requests)
- [Database Console Commands](#database-console-commands)
- [Background Jobs (Sidekiq)](#background-jobs-sidekiq)
- [Real-time Updates (ActionCable)](#real-time-updates-actioncable)
- [Architecture Diagram](#architecture-diagram)

## System Requirements

*   Ruby (version specified in `.ruby-version`, e.g., 3.3.0)
*   PostgreSQL (with PostGIS extension enabled)
*   Redis (for Sidekiq and ActionCable)

## Setup

1.  **Clone the repository:**
    ```bash
    git clone <repository_url>
    cd rideHailing
    ```

2.  **Install dependencies:**
    ```bash
    bundle install
    ```

### Database Configuration

SafeRideNG uses PostgreSQL with the PostGIS extension.

1.  **Create PostgreSQL roles (if not already present):**
    Ensure your PostgreSQL user has the necessary permissions. You might need to create a user with `CREATE DATABASE` privileges.

2.  **Configure `config/database.yml`:**
    Adjust the `username` and `password` in `config/database.yml` to match your local PostgreSQL setup.

3.  **Enable PostGIS extension:**
    After creating your database, you need to enable the PostGIS extension. This is typically done via a migration, but you can also do it manually in your PostgreSQL client:
    ```sql
    CREATE EXTENSION postgis;
    ```

### Environment Variables

The application uses `dotenv-rails` for managing environment variables in development and test environments.

1.  **Create `.env` file:**
    Create a file named `.env` in the root directory of the project.

2.  **Add `DEVISE_JWT_SECRET_KEY`:**
    Generate a strong secret key for Devise JWT authentication.
    ```bash
    rails secret
    ```
    Copy the generated key and add it to your `.env` file:
    ```
    DEVISE_JWT_SECRET_KEY=<your_generated_secret_key>
    ```

3.  **Configure `config/credentials.yml.enc`:**
    The `DEVISE_JWT_SECRET_KEY` is also expected in `config/credentials.yml.enc` for production and potentially other environments.
    ```bash
    EDITOR="nano" rails credentials:edit
    ```
    Add the `devise_jwt_secret_key` under the appropriate environment (e.g., `development:` or `production:`):
    ```yaml
    # config/credentials.yml.enc
    development:
      devise_jwt_secret_key: <your_generated_secret_key>
    ```

### Migrations

Run database migrations to set up the schema, including PostGIS columns and indexes.

```bash
rails db:migrate
```

If you encounter issues with PostGIS during `db:reset` or `db:migrate` (e.g., `PG::DependentObjectsStillExist`), you might need to manually drop the PostGIS extension before dropping the database.

### Running the Application

1.  **Start the Rails server:**
    ```bash
    rails s
    ```
    The API will typically run on `http://localhost:3000`.

2.  **Start Sidekiq (for background jobs):**
    ```bash
    bundle exec sidekiq -C config/sidekiq.yml
    ```

## Testing the API with cURL

This section provides `cURL` commands to test the various GraphQL mutations and queries. Replace `http://localhost:3000` with your actual backend URL if different.

**Important:**
*   Replace `YOUR_JWT_TOKEN` with a valid JWT token obtained from the `Login` mutation.
*   IDs (e.g., `rideId`, `driverId`) are UUIDs and will vary based on your database. Update them as you create records.

### GraphQL Endpoint

All GraphQL requests are sent to `POST /graphql`.

### Authentication (Login)

First, create a user if you haven't already. Then, log in to get a JWT token.

```bash
# Login as customer
curl -X POST http://localhost:3000/graphql \
  -H "Content-Type: application/json" \
  -d '{
    "query": "mutation Login($input: LoginInput!) { login(input: $input) { user { id email } token errors } }",
    "variables": {
      "input": {
        "login": "customer_test@example.com",
        "password": "password"
      }
    }
  }'

# Login as driver
curl -X POST http://localhost:3000/graphql \
  -H "Content-Type: application/json" \
  -d '{
    "query": "mutation Login($input: LoginInput!) { login(input: $input) { user { id email } token errors } }",
    "variables": {
      "input": {
        "login": "driver_test@example.com",
        "password": "password"
      }
    }
  }'
```

### Creating a User

```bash
```bash
curl -X POST http://localhost:3000/graphql 
  -H "Content-Type: application/json" 
  -d '{
    "query": "mutation CreateUser($input: CreateUserInput!) { createUser(input: $input) { user { id email } errors } }",
    "variables": {
      "input": {
        "email": "new_user@example.com",
        "password": "password",
        "passwordConfirmation": "password",
        "firstName": "New",
        "lastName": "User",
        "phoneNumber": "+15551234567"
      }
    }
  }'
```
```

### Creating a Driver Profile

Requires a logged-in driver user.

```bash
curl -X POST http://localhost:3000/graphql \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "query": "mutation CreateDriverProfile($input: CreateDriverProfileInput!) { createDriverProfile(input: $input) { driver { id user { id } licensePlate carModel carColor } errors } }",
    "variables": {
      "input": {
        "licensePlate": "DRV123",
        "carModel": "Toyota Camry",
        "carColor": "Silver"
      }
    }
  }'
```

### Creating an Emergency Contact

Requires a logged-in user (customer or driver).

```bash
curl -X POST http://localhost:3000/graphql \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "query": "mutation CreateEmergencyContact($input: CreateEmergencyContactInput!) { createEmergencyContact(input: $input) { emergencyContact { id name whatsappNumber } errors } }",
    "variables": {
      "input": {
        "name": "Emergency Contact Name",
        "whatsappNumber": "+15559876543"
      }
    }
  }'
```

### Creating a Scheduled Ride Request

Requires a logged-in customer with at least one emergency contact.

```bash
curl -X POST http://localhost:3000/graphql \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "query": "mutation CreateScheduledRideRequest($input: CreateScheduledRideRequestInput!) { createScheduledRideRequest(input: $input) { rideRequest { id pickupTime destination maxPassengers proposedFare requireVerifiedPassengers pickupLocation { latitude longitude } } errors } }",
    "variables": {
      "input": {
        "pickupTime": "2025-07-23T10:00:00Z",
        "destination": "{\"latitude\": 34.0522, \"longitude\": -118.2437, \"address\": \"Los Angeles, CA\"}",
        "maxPassengers": 2,
        "proposedFare": 25.50,
        "requireVerifiedPassengers": true,
        "pickupLocation": { "lat": 34.0522, "lng": -118.2437 }
      }
    }
  }'
```

### Creating a Ride (Driver Accepts)

Requires a logged-in driver and an existing `rideRequestId` and `driverId` (from the `Driver` profile).

```bash
curl -X POST http://localhost:3000/graphql \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "query": "mutation CreateRide($input: CreateRideInput!) { createRide(input: $input) { ride { id driver { id } rideRequest { id } location { latitude longitude } } errors } }",
    "variables": {
      "input": {
        "rideRequestId": "YOUR_RIDE_REQUEST_ID",
        "driverId": "YOUR_DRIVER_PROFILE_ID",
        "location": { "lat": 34.0522, "lng": -118.2437 }
      }
    }
  }'
```

### Joining a Ride

Requires a logged-in customer and an existing `rideId`.

```bash
curl -X POST http://localhost:3000/graphql \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "query": "mutation JoinRide($input: JoinRideInput!) { joinRide(input: $input) { ride { id } errors } }",
    "variables": {
      "input": {
        "rideId": "YOUR_RIDE_ID"
      }
    }
  }'
```

### Submitting a Rating

Requires a logged-in user, an existing `rideId`, and a `rateeId` (the user ID of the person being rated, e.g., the driver's user ID).

```bash
curl -X POST http://localhost:3000/graphql \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "query": "mutation SubmitRating($input: SubmitRatingInput!) { submitRating(input: $input) { rating { id score } errors } }",
    "variables": {
      "input": {
        "rideId": "YOUR_RIDE_ID",
        "rateeId": "USER_ID_OF_RATEE",
        "score": 5
      }
    }
  }'
```

### Creating a Ride Share Link

Requires a logged-in user and an existing `rideId`.

```bash
curl -X POST http://localhost:3000/graphql \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "query": "mutation CreateRideShare($input: CreateRideShareInput!) { createRideShare(input: $input) { shareableLink errors } }",
    "variables": {
      "input": {
        "rideId": "YOUR_RIDE_ID"
      }
    }
  }'
```

### Sending an Emergency Alert

Requires a logged-in user and an existing `rideId`.

```bash
curl -X POST http://localhost:3000/graphql \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "query": "mutation SendEmergencyAlert($input: SendEmergencyAlertInput!) { sendEmergencyAlert(input: $input) { success errors } }",
    "variables": {
      "input": {
        "rideId": "YOUR_RIDE_ID"
      }
    }
  }'
```

### Querying Driver Information

Requires a logged-in user and a `driverId` (the ID of the `Driver` profile, not the `User` ID).

```bash
curl -X POST http://localhost:3000/graphql \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "query": "query GetDriver($id: ID!) { driver(id: $id) { id user { id email } licensePlate carModel carColor } }",
    "variables": {
      "id": "YOUR_DRIVER_PROFILE_ID"
    }
  }'
```

### Querying User Profile

Requires a logged-in user.

```bash
curl -X POST http://localhost:3000/graphql \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "query": "query GetProfile { profile { id user { id } firstName lastName } }"
  }'
```

### Querying Nearby Rides

Requires a logged-in user.

```bash
curl -X POST http://localhost:3000/graphql \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "query": "query GetNearbyRides($lat: Float!, $lng: Float!) { nearbyRides(lat: $lat, lng: $lng) { id location { latitude longitude } } }",
    "variables": {
      "lat": 34.0522,
      "lng": -118.2437
    }
  }'
```

### Querying Scheduled Ride Requests

Requires a logged-in user.

```bash
curl -X POST http://localhost:3000/graphql \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "query": "query GetScheduledRideRequests { scheduledRideRequests { id pickupTime destination } }"
  }'
```

## Database Console Commands

You can interact with the database directly using the Rails console:

```bash
ruby
rails console
```

Useful commands:

*   **List all users:**
    ```ruby
    User.all
    ```
*   **List drivers (users with a driver profile):**
    ```ruby
    User.joins(:driver).distinct
    # Or to see the driver profiles directly:
    Driver.all
    ```
*   **List customers (users with a profile but no driver profile):**
    ```ruby
    User.joins(:profile).left_outer_joins(:driver).where(drivers: { id: nil }).distinct
    ```
*   **Reset the database (development/test):**
    ```bash
    rails db:reset
    ```
    If you encounter issues with PostGIS during `db:reset`, you might need to manually drop the PostGIS extension before dropping the database.

## Background Jobs (Sidekiq)

Sidekiq processes background jobs. Ensure it's running alongside your Rails server.

*   **Start Sidekiq:**
    ```bash
    bundle exec sidekiq -C config/sidekiq.yml
    ```
*   **Sidekiq Web UI:**
    If configured, you can access the Sidekiq Web UI (usually at `/sidekiq` if mounted in `routes.rb`) to monitor job queues and status.

## Real-time Updates (ActionCable)

ActionCable provides real-time functionality, primarily for GraphQL subscriptions.

*   **WebSocket Endpoint:** ActionCable typically runs on `/cable`.
*   **Testing Subscriptions:** You'll need a GraphQL client that supports subscriptions (e.g., Apollo Client, Relay, or a tool like GraphiQL with WebSocket support) to test real-time updates.

## Architecture Diagram

The backend architecture is depicted in the `architecture_diagram.drawio.xml` file in the root of this repository. You can import this file into [Draw.io](https://app.diagrams.net/) to view and edit the diagram.

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