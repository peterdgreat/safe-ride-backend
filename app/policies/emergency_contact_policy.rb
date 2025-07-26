class EmergencyContactPolicy < ApplicationPolicy
  def create?
    Rails.logger.debug "Pundit: current_user = #{user.inspect}"
    Rails.logger.debug "Pundit: record = #{record.inspect}"
    Rails.logger.debug "Pundit: record.class = #{record.class}"
    # For create? policy, record is typically the class itself.
    # We just need to check if a user is present to create an emergency contact.
    user.present?
  end

  def update?
    user == record.user
  end

  def destroy?
    user == record.user
  end
end