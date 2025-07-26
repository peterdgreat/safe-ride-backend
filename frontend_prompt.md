**Subject: Frontend Development Roadmap - SafeRideNG Backend Integration**

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

### **Feature Breakdown:**

Please implement/update the following features:

#### **1. Authentication & User Management:**

*   **Login:**
    *   **Update:** Ensure robust error handling for invalid credentials, displaying the exact error message received from the backend (e.g., "Cannot return null for non-nullable field LoginPayload.token" or "Invalid credentials").
*   **User Registration:**
    *   **Update:** The backend now requires `firstName`, `lastName`, and `phoneNumber` during user creation. Update the registration form to include these fields and ensure they are sent with the mutation.
*   **User Profile Display:**
    *   **Update:** Display the user's `is_verified` status prominently on their profile.
*   **Driver Profile Creation:**
    *   **New Feature:** Implement a form that allows a logged-in user to create a driver profile. This form should capture `licensePlate`, `carModel`, and `carColor`.
*   **Emergency Contact Management:**
    *   **New Feature:** Implement a section where users can add and view their emergency contacts.
    *   **Enhancement:** Before allowing a user to create a scheduled ride request, the frontend must check if at least one emergency contact exists. If not, display a clear message (e.g., "Add emergency contact fess!") and guide the user to add one.

#### **2. Ride Management:**

*   **Scheduled Ride Request Creation:**
    *   **Update:** The backend now accepts `pickupLocation` as a spatial input (`lat`, `lng`). Update the ride request form to capture these coordinates (e.g., via map selection or manual input) and send them with the mutation.
*   **Ride Creation (Driver Accepts):**
    *   **New Feature (for Drivers):** Implement a UI for drivers to accept an existing ride request. This will involve sending the `rideRequestId`, `driverId`, and the driver's current `location` (`lat`, `lng`) via the `CreateRide` mutation.
*   **Ride Share Link Creation:**
    *   **New Feature:** Implement functionality to create and display a shareable link for a ride.
*   **Emergency Alert Sending:**
    *   **New Feature:** Implement a button or mechanism for a logged-in user to send an emergency alert for an active ride. Provide clear feedback once the alert is sent.

#### **3. Location-Based Features:**

*   **Nearby Rides Query:**
    *   **Update:** Ensure the frontend sends `lat` and `lng` as arguments to the `nearbyRides` query.
    *   **Update:** Display the `latitude` and `longitude` of the returned ride locations. If your frontend uses maps, integrate these coordinates for visual representation.
*   **Displaying Spatial Data:**
    *   **Enhancement:** For any feature displaying ride or ride request details, ensure `pickupLocation` and `dropoff_location` (if available) are visually represented (e.g., on a map component).

#### **4. Real-time & Notifications:**

*   **Real-time Ride Updates:**
    *   **New Feature:** Implement GraphQL subscriptions for the `rideUpdated` event. This should allow the frontend to receive and display live updates on ride status changes (e.g., driver approaching, ride started, ride completed) and potentially the driver's live location during a ride.
*   **Backend Notifications:**
    *   **Enhancement:** Be prepared to display user-facing messages from the backend, such as confirmations for SMS/WhatsApp notifications sent to emergency contacts.

---

Please let me know if you have any questions or require further clarification on any of these points.

Thanks,
[Your Name/Team]

---