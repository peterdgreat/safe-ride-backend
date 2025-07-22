module Types
  class ProfileType < Types::BaseObject
    field :id, ID, null: false
    field :user, Types::UserType, null: false
    field :first_name, String, null: true
    field :last_name, String, null: true
    field :date_of_birth, GraphQL::Types::ISO8601Date, null: true
    field :gender, String, null: true
    field :profile_picture_url, String, null: true
  end
end