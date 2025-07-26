# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_07_24_202917) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"
  enable_extension "postgis"

  create_table "drivers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "license_plate"
    t.string "car_model"
    t.string "car_color"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_drivers_on_user_id"
  end

  create_table "emergency_contacts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "name"
    t.string "whatsapp_number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_emergency_contacts_on_user_id"
  end

  create_table "profiles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "first_name"
    t.string "last_name"
    t.date "date_of_birth"
    t.string "gender"
    t.string "profile_picture_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_profiles_on_user_id"
  end

  create_table "ratings", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "ride_id", null: false
    t.uuid "ratee_id", null: false
    t.integer "score"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ratee_id"], name: "index_ratings_on_ratee_id"
    t.index ["ride_id"], name: "index_ratings_on_ride_id"
  end

  create_table "ride_passengers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "ride_id", null: false
    t.uuid "passenger_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.geography "dropoff_location", limit: {:srid=>4326, :type=>"geometry", :geographic=>true}, null: false
    t.float "fare_amount"
    t.index ["dropoff_location"], name: "index_ride_passengers_on_dropoff_location", using: :gist
    t.index ["passenger_id"], name: "index_ride_passengers_on_passenger_id"
    t.index ["ride_id"], name: "index_ride_passengers_on_ride_id"
  end

  create_table "ride_requests", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "passenger_id", null: false
    t.datetime "pickup_time"
    t.json "destination"
    t.integer "max_passengers"
    t.float "proposed_fare"
    t.boolean "require_verified_passengers"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.geography "pickup_location", limit: {:srid=>4326, :type=>"geometry", :geographic=>true}, null: false
    t.float "estimated_fare"
    t.index ["passenger_id"], name: "index_ride_requests_on_passenger_id"
    t.index ["pickup_location"], name: "index_ride_requests_on_pickup_location", using: :gist
  end

  create_table "rides", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "driver_id", null: false
    t.uuid "ride_request_id", null: false
    t.datetime "start_time"
    t.datetime "end_time"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.geography "location", limit: {:srid=>4326, :type=>"geometry", :geographic=>true}
    t.index ["driver_id"], name: "index_rides_on_driver_id"
    t.index ["location"], name: "index_rides_on_location", using: :gist
    t.index ["ride_request_id"], name: "index_rides_on_ride_request_id"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "phone_number"
    t.string "first_name"
    t.string "last_name"
    t.boolean "is_verified", default: false
    t.string "preferred_language", default: "en"
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "jti"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["jti"], name: "index_users_on_jti"
    t.index ["phone_number"], name: "index_users_on_phone_number", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "drivers", "users"
  add_foreign_key "emergency_contacts", "users"
  add_foreign_key "profiles", "users"
  add_foreign_key "ratings", "rides"
  add_foreign_key "ratings", "users", column: "ratee_id"
  add_foreign_key "ride_passengers", "rides"
  add_foreign_key "ride_passengers", "users", column: "passenger_id"
  add_foreign_key "ride_requests", "users", column: "passenger_id"
  add_foreign_key "rides", "ride_requests"
  add_foreign_key "rides", "users", column: "driver_id"
end
