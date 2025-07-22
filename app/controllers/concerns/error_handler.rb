module ErrorHandler
  extend ActiveSupport::Concern

  included do
    rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
    rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

    private

    def user_not_authorized
      render json: { errors: ["You are not authorized to perform this action."] }, status: :forbidden
    end

    def record_not_found
      render json: { errors: ["Record not found."] }, status: :not_found
    end
  end
end