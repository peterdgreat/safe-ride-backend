class RideRequestPolicy < ApplicationPolicy
  def show?
    true
  end

  def create?
    true # Anyone can create a ride request
  end

  def update?
    user == record.passenger
  end

  def destroy?
    user == record.passenger
  end

  class Scope < Scope
    def resolve
      scope.all
    end
  end
end