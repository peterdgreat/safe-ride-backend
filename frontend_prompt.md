# Frontend Development Roadmap - SafeRideNG Backend Integration

Hi [Frontend Developer's Name],

This document outlines the next phase of frontend development for SafeRideNG, focusing on integrating with the recently stabilized backend API. The goal is to fully leverage the backend's capabilities, ensuring a robust and feature-rich user experience.

The backend is built with Ruby on Rails and exposes a **GraphQL API**. We've also implemented **ActionCable for real-time updates** and extensively used **RGeo for spatial data handling**.

Please review the following instructions carefully. Your task involves adding new features, updating existing ones, and ensuring comprehensive error handling and user feedback.

---

### **General Instructions:**

1.  **GraphQL API:** All communication with the backend should be via the GraphQL API. Refer to the `README.md` in the backend repository for cURL examples and the overall API structure.
2.  **Real-time Updates:** Implement GraphQL subscriptions where indicated to provide real-time user experiences.
3.  **Spatial Data:** Ensure all location-based inputs (`lat`, `lng`) and outputs (`latitude`, `longitude`) are handled correctly and displayed appropriately (e.g., on maps). Refer to `rgeo.md` in the backend repository for detailed explanations on spatial data handling.
4.  **Error Handling & User Feedback:** For every API interaction, implement clear loading states, success messages, and graceful error handling. Display error messages received from the backend directly to the user, including any Pidgin-specific messages.
5.  **IDs:** All record IDs are UUIDs; ensure your frontend handles them correctly.
6.  **Documentation:** Refer to the backend's `README.md`, `rgeo.md`, and `placeholder.md` files for detailed API information, spatial data nuances, and areas marked for future refinement.

---

### **Feature Breakdown & UI Considerations:**

Please implement/update the following features, considering the suggested UI components:

#### **1. Authentication & User Management:**

*   **Login:**
    *   **Existing UI:** Login form.
    *   **Instructions:**
        *   Ensure robust error handling for invalid credentials.
        *   Display the exact error message received from the backend (e.g., "Cannot return null for non-nullable field LoginPayload.token" or "Invalid credentials") prominently near the input fields or as a general alert.

*   **User Registration:**
    *   **Existing UI:** Registration form.
    *   **Instructions:**
        *   Add new input fields for `firstName`, `lastName`, and `phoneNumber`.
        *   Implement client-side validation for these new fields (e.g., phone number format).

*   **User Profile Display:**
    *   **Existing UI:** User profile screen/component.
    *   **Instructions:**
        *   Add a clear visual indicator (e.g., a "Verified" badge, a checkmark icon) next to the user's name or email to show their `is_verified` status.

*   **Driver Profile Creation:**
    *   **New UI:** A dedicated "Become a Driver" or "Create Driver Profile" screen/form, accessible from the user's profile or a main navigation menu.
    *   **Instructions:**
        *   This form should include input fields for `licensePlate`, `carModel`, and `carColor`.
        *   Implement client-side validation for these fields.
        *   Upon successful creation, redirect the user to their updated profile, a new "Driver Dashboard" view, or display a success message.

*   **Emergency Contact Management:**
    *   **New UI:** A "Emergency Contacts" section within the user's profile or settings.
    *   **Instructions:**
        *   This section should display a list of existing emergency contacts (if any), showing their `name` and `whatsappNumber`.
        *   Provide a prominent "Add New Contact" button that opens a modal or navigates to a dedicated form with input fields for `name` and `whatsappNumber`.
        *   Implement functionality to **edit** and **delete** existing contacts from this list.
        *   **Enhancement (Pre-Ride Request Check):** Before allowing a user to proceed with creating a scheduled ride request, implement a check. If no emergency contacts exist, display a prominent alert (e.g., a modal, a banner at the top of the ride request form) with the message "Add emergency contact fess!" and a direct link/button to the "Emergency Contacts" section.

#### **2. Ride Management:**

*   **Scheduled Ride Request Creation:**
    *   **Existing UI:** Ride request form.
    *   **Instructions:**
        *   **`pickupLocation` Input:** Replace the current text input for `pickupLocation` with an interactive map component (e.g., using Leaflet, Google Maps API, Mapbox GL JS). Users should be able to:
            *   Click on the map to select a pickup point, which automatically populates the `lat` and `lng` coordinates.
            *   Occasionally, allow users to search for an address, which then centers the map and selects the corresponding coordinates.
        *   **`destination` Input:** If `destination` is currently a simple text input, ensure that the frontend correctly stringifies the `latitude`, `longitude`, and `address` into a JSON string before sending it to the backend. Conversely, when displaying, parse this JSON string.
        *   Ensure all other required fields (`pickupTime`, `maxPassengers`, `proposedFare`, `requireVerifiedPassengers`) are captured and sent.

*   **Ride Creation (Driver Accepts):**
    *   **New UI:** A "Driver Dashboard" or "Available Ride Requests" screen for drivers.
    *   **Instructions:**
        *   This screen should display a list of pending ride requests that a driver can accept.
        *   For each request, display relevant details (pickup, destination, proposed fare, passengers).
        *   Provide an "Accept Ride" button for each request.
        *   When "Accept Ride" is clicked, trigger the `CreateRide` mutation. The driver's **current location** (`lat`, `lng`) should be automatically captured (e.g., via the browser's Geolocation API) and sent with the mutation.
        *   After accepting, the UI should transition to an "Active Ride" view for the driver.

*   **Ride Share Link Creation:**
    *   **Existing UI:** Active ride details screen (for passengers).
    *   **Instructions:**
        *   Add a "Share Ride" button or icon.
        *   Upon clicking, trigger the `CreateRideShare` mutation, passing the `rideId`.
        *   Display the returned `shareableLink` to the user (e.g., in a modal, a copy-to-clipboard component, or directly as a shareable URL).

*   **Emergency Alert Sending:**
    *   **Existing UI:** Active ride details screen (for both passengers and drivers).
    *   **Instructions:**
        *   Implement a prominent "Emergency Alert" button (e.g., a red SOS button, clearly labeled).
        *   Upon clicking, trigger the `SendEmergencyAlert` mutation, passing the `rideId`.
        *   Provide immediate visual feedback (e.g., a temporary "Alert Sent!" message, a toast notification) and potentially a confirmation dialog before sending.

#### **3. Location-Based Features:**

*   **Nearby Rides Query:**
    *   **Existing UI:** A map view or a list of available rides.
    *   **Instructions:**
        *   When querying nearby rides, ensure the user's current location (`lat`, `lng`) is sent as arguments to the `nearbyRides` query.
        *   Display the returned rides on a map component, using their `pickupLocation` and `dropoff_location` (if available) coordinates.
        *   Provide a mechanism for users to refresh nearby rides based on their current location or a selected point on the map.

*   **Displaying Spatial Data:**
    *   **Existing UI:** Any screen displaying ride details, ride request details, or driver/passenger locations.
    *   **Instructions:**
        *   For `pickupLocation` and `dropoff_location` fields, ensure they are correctly parsed from the backend's `latitude`/`longitude` format.
        *   Visually represent these locations on a map component within the respective detail screens.

#### **4. Real-time & Notifications:**

*   **Real-time Ride Updates:**
    *   **Existing UI:** Active ride tracking screen (for both passenger and driver).
    *   **Instructions:**
        *   Implement a GraphQL subscription to the `rideUpdated` event, subscribing with the relevant `rideId`.
        *   As updates are received via the subscription, dynamically update the ride's status (e.g., "Driver En Route", "Arrived at Pickup", "Ride Started", "Ride Completed") and the driver's live location on the map.
        *   Display user-friendly notifications (e.g., "Your driver is 5 minutes away", "Ride has started") based on these real-time status changes.

*   **Backend Notifications:**
    *   **Existing UI:** General notification area (e.g., a toast notification system, an in-app notification center).
    *   **Instructions:**
        *   Implement a generic mechanism to display user-facing messages received from the backend's `errors` or `success` fields for any mutation or query.
        *   This is particularly important for confirmations (e.g., "Emergency alert sent successfully!") or specific error messages (e.g., "Phone number has already been taken").

---

Please let me know if you have any questions or require further clarification on any of these points.

Thanks,
[Your Name/Team]

---