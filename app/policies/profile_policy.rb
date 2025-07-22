class ProfilePolicy < ApplicationPolicy
  def show?
    true
  end

  def create?
    user == record.user
  end

  def update?
    user == record.user
  end

  def destroy?
    user == record.user
  end

  class Scope < Scope
    def resolve
      scope.all
    end
  end
end