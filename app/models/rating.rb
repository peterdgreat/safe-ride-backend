class Rating < ApplicationRecord
  belongs_to :ride
  belongs_to :ratee, class_name: 'User'
end
