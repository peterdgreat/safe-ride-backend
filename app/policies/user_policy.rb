class UserPolicy < ApplicationPolicy
  def show?
    true # Anyone can view a user's public profile
  end

  def update?
    user == record # Only a user can update their own profile
  end

  def destroy?
    user == record # Only a user can destroy their own account
  end

  class Scope < Scope
    def resolve
      scope.all
    end
  end
end