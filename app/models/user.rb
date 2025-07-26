class User < ApplicationRecord
  attr_accessor :login

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :jwt_authenticatable, jwt_revocation_strategy: self

  has_one :profile, dependent: :destroy
  has_many :emergency_contacts, dependent: :destroy
  has_one :driver, dependent: :destroy

  validates_presence_of :email, :phone_number, :first_name, :last_name
  validates_uniqueness_of :email, case_sensitive: false
  validates_uniqueness_of :phone_number
  validates_length_of :password, minimum: 6, if: -> { new_record? || changes[:password] }

  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    if login = conditions.delete(:login)
      where(conditions.to_h).where(["lower(email) = :value OR lower(phone_number) = :value", { value: login.downcase }]).first
    elsif conditions.has_key?(:email) || conditions.has_key?(:phone_number)
      where(conditions.to_h).first
    end
  end

  include Devise::JWT::RevocationStrategies::JTIMatcher

  def generate_jwt
    JWT.encode({ jti: self.jti, sub: self.id, scp: "user", aud: nil, exp: (Time.now + 1.day).to_i }, Rails.application.credentials.devise_jwt_secret_key)
  end
end