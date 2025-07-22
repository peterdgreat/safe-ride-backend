class DriverPolicy < ApplicationPolicy
  def show?
    true # For now, allow any user to view a driver for testing purposes
  end
end