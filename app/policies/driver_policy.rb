class DriverPolicy < ApplicationPolicy
  def show?
    Rails.logger.debug "DriverPolicy#show?: user = #{user.inspect}, record = #{record.inspect}"
    user.present? # Allow viewing only if a user is present
  end
end