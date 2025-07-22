class RidePolicy < ApplicationPolicy
  def create?
    user.is_a?(User) && user.driver.present?
  end

  def join?
    true # For now, allow any user to join a ride for testing purposes
  end

  def create_share?
    true # For now, allow any user to create a share link for testing purposes
  end

  def send_emergency_alert?
    true # For now, allow any user to send an emergency alert for testing purposes
  end

  class Scope < Scope
    def resolve
      scope.all # For now, allow any user to see all rides for testing purposes
    end
  end
end