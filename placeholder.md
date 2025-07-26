# Placeholder and Future Work Items

This document outlines areas in the codebase where temporary solutions, simplified implementations, or debugging artifacts have been introduced. These items should be revisited for future development, refactoring, or production readiness.

## 1. Core Business Logic Placeholders

### 1.1 Ride Request - Estimated Fare Calculation

*   **Location:** `app/models/ride_request.rb` (`calculate_estimated_fare` method)
*   **Current State:** The `estimated_distance_km` is hardcoded to `10.0`.
*   **Future Work:** Replace this placeholder with a dynamic distance calculation. This will likely involve:
    *   Integration with a mapping/routing API (e.g., Google Maps API, Mapbox API) to calculate actual road distances between `pickup_location` and `destination`.
    *   Consideration of real-time traffic data and historical traffic patterns for more accurate time and distance estimations.
    *   Handling of multiple passenger stops if ride-sharing features are expanded.

### 1.2 Ride - Location Handling

*   **Location:** `app/models/ride.rb` (custom `location=` setter)
*   **Current State:** The `location=` setter explicitly converts `RGeo::Feature::Point` objects to WKT strings (`value.as_text`) for storage.
*   **Future Work:** While this works around the `TypeError: can't quote RGeo::Geographic::SphericalPointImpl` we faced, ideally, `activerecord-postgis-adapter` should handle direct storage of `RGeo::Feature::Point` objects without manual conversion. Investigate if future versions of `rgeo-activerecord` or `activerecord-postgis-adapter` allow for simpler direct assignment, removing the need for this custom setter.

### 1.3 Ride Request - Destination Field

*   **Location:** `app/models/ride_request.rb` (and related GraphQL types/mutations)
*   **Current State:** The `destination` field is stored as a JSON string (e.g., `{"latitude":..., "longitude":..., "address":"..."}`).
*   **Future Work:** If the `destination` requires more complex behavior, validation, or querying, consider:
    *   Creating a dedicated `Destination` model or a value object to encapsulate destination-related logic.
    *   Defining a more structured GraphQL `DestinationInputType` and `DestinationType` to avoid passing raw JSON strings.

## 2. External Service Integrations

### 2.1 Africa's Talking API Calls (SMS and WhatsApp)

*   **Location:** `app/jobs/send_sms_job.rb`, `app/jobs/send_whatsapp_job.rb`
*   **Current State:** The actual API calls to Africa's Talking are commented out (`# AfricaTalking.send_sms(recipient, message)`).
*   **Future Work:** Implement the actual integration with the Africa's Talking SDK or direct HTTP calls to send SMS and WhatsApp messages. This includes:
    *   Configuring API keys and credentials securely.
    *   Implementing proper error handling and retry mechanisms for failed API calls.
    *   Considering message templates and internationalization.

### 2.2 USSD Controller Logic

*   **Location:** `app/controllers/ussd_controller.rb` (conceptual implementation)
*   **Current State:** The controller contains `puts` statements and simplified conditional logic for handling USSD requests.
*   **Future Work:** Fully implement the USSD flow, integrating with Africa's Talking USSD gateway. This involves:
    *   Robust parsing of USSD input (`text`).
    *   Calling appropriate services or background jobs for complex operations (e.g., creating ride requests, adding emergency contacts).
    *   Managing session state for multi-step USSD interactions.
    *   Implementing proper error handling and user feedback within the USSD response.

## 3. Authorization Placeholders

### 3.1 Driver Policy - `show?` method

*   **Location:** `app/policies/driver_policy.rb`
*   **Current State:** The `show?` method simply checks `user.present?`.
*   **Future Work:** Refine the authorization logic. For example, only allow:
    *   The driver themselves to view their profile.
    *   Admins or specific roles to view any driver profile.
    *   Users who have previously ridden with the driver to view their profile.

### 3.2 General Pundit Policies

*   **Location:** `app/policies/*.rb`
*   **Current State:** Policies often have basic `user.present?` or `user == record.user` checks.
*   **Future Work:** Review and implement more granular authorization rules for all actions (create, show, update, destroy) across all models, considering different user roles (customer, driver, admin) and verification statuses (`is_verified`).

## 4. Debugging and Logging Artifacts

### 4.1 `Rails.logger.debug` Statements

*   **Location:**
    *   `app/graphql/mutations/create_ride_request.rb`
    *   `app/policies/emergency_contact_policy.rb`
    *   `app/policies/driver_policy.rb`
    *   `app/jobs/send_sms_job.rb`
    *   `app/jobs/send_whatsapp_job.rb`
*   **Current State:** Debugging `Rails.logger.debug` statements are present to aid in development and troubleshooting.
*   **Future Work:** Review these logs before deploying to production. Either:
    *   Remove them if they are no longer needed.
    *   Change their logging level to `debug` or `info` as appropriate, ensuring they don't clutter production logs or expose sensitive information.

### 4.2 Test-Specific Logger Overrides

*   **Location:** `spec/jobs/send_sms_job_spec.rb`, `spec/jobs/send_whatsapp_job_spec.rb`
*   **Current State:** Tests temporarily override `Rails.logger` with `StringIO` to capture log output for assertions.
*   **Future Work:** While necessary for testing, ensure these overrides are properly reset after each test to avoid interfering with other tests or the overall test environment. The current implementation with `original_logger = Rails.logger` and `Rails.logger = original_logger` handles this correctly, but it's a pattern to be aware of.

## 5. Test Data and Setup

### 5.1 Hardcoded Test Data in cURL Commands

*   **Location:** `README.md`
*   **Current State:** cURL commands use hardcoded IDs and values (e.g., `YOUR_RIDE_REQUEST_ID`, `YOUR_DRIVER_PROFILE_ID`).
*   **Future Work:** These are for manual testing. For automated testing, use factories (like FactoryBot) to generate dynamic and unique test data.

## 6. General Code Refinements

### 6.1 `FareCalculator` Module Warnings

*   **Location:** `app/models/concerns/fare_calculator.rb`
*   **Current State:** Warnings about "already initialized constant" appear during test runs.
*   **Future Work:** Investigate the cause of these warnings. It might be related to class reloading in the development/test environment. Ensure constants are defined in a way that avoids re-initialization or consider alternative ways to manage configuration values if they are truly constant.

By addressing these placeholders and future work items, the application can evolve from an MVP to a more robust, scalable, and production-ready system.
