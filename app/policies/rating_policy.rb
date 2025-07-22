class RatingPolicy < ApplicationPolicy
  def create?
    user.is_a?(User) && record.ride.passengers.include?(user)
  end

  def show?
    true
  end

  def update?
    user.is_a?(User) && record.ride.passengers.include?(user)
  end

  def destroy?
    user.is_a?(User) && record.ride.passengers.include?(user)
  end

  class Scope < Scope
    def resolve
      scope.all
    end
  end
end