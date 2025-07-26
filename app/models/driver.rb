class Driver < ApplicationRecord
  belongs_to :user

  validates_presence_of :license_plate, :car_model, :car_color
end