class EmergencyContact < ApplicationRecord
  belongs_to :user
  validates :name, presence: true
  validates :whatsapp_number, presence: true
end