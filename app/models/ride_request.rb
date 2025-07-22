class RideRequest < ApplicationRecord
  belongs_to :passenger, class_name: 'User'
end
