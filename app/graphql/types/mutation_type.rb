# frozen_string_literal: true

module Types
  class MutationType < Types::BaseObject
    field :create_user, mutation: Mutations::CreateUser
    field :login, mutation: Mutations::Login
    field :create_emergency_contact, mutation: Mutations::CreateEmergencyContact
    field :create_scheduled_ride_request, mutation: Mutations::CreateScheduledRideRequest
    field :join_ride, mutation: Mutations::JoinRide
    field :submit_rating, mutation: Mutations::SubmitRating
    field :create_ride_share, mutation: Mutations::CreateRideShare
    field :send_emergency_alert, mutation: Mutations::SendEmergencyAlert
    field :create_driver_profile, mutation: Mutations::CreateDriverProfile
    field :create_ride, mutation: Mutations::CreateRide
    field :create_profile, mutation: Mutations::CreateProfile
  end
end
