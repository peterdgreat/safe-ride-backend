# frozen_string_literal: true

class GraphqlController < ApplicationController
  # If accessing from outside this domain, nullify the session
  # This allows for outside API access while preventing CSRF attacks,
  # but you'll have to authenticate your user separately


  def execute
    variables = prepare_variables(params[:variables])
    query = params[:query]
    current_user = is_public_mutation? ? nil : authenticate_user_from_jwt
    return if performed?
    operation_name = params[:operationName]
    context = {
      current_user: current_user,
    }
    result = RideHailingSchema.execute(query, variables: variables, context: context, operation_name: operation_name)
    render json: result
  rescue Pundit::NotAuthorizedError => e
    render json: { errors: [{ message: e.message }] }, status: :unauthorized
  rescue => e
    raise e
  end

  private

  # Handle variables in form data, JSON body, or a blank value
  def prepare_variables(variables_param)
    case variables_param
    when String
      if variables_param.present?
        JSON.parse(variables_param) || {}
      else
        {}
      end
    when Hash
      variables_param
    when ActionController::Parameters
      variables_param.to_unsafe_hash # GraphQL-Ruby will validate name and type of incoming variables.
    when nil
      {}
    else
      raise ArgumentError, "Unexpected parameter: #{variables_param}"
    end
  end


  def is_public_mutation?
    query = params[:query]
    return false unless query

    query.match?(/mutation\s*(?:SignUp|login)\s*(?:\([^)]*\))?\s*{\s*(signUp|login)\s*\(/i) ||
      params[:operationName]&.match?(/^(SignUp|login)$/i)
  end

  def authenticate_user_from_jwt
    token = request.headers['Authorization']&.split('Bearer ')&.last
    return nil unless token

    begin
      payload = JWT.decode(token, Rails.application.credentials.devise_jwt_secret_key, true, { algorithm: 'HS256' }).first
      user = User.find_by(jti: payload['jti'])
      if user
        Rails.logger.debug "JWT Auth Success: User ID=#{user.id}, JTI=#{payload['jti']}"
        return user
      else
        Rails.logger.warn "Invalid JWT: User not found for jti #{payload['jti']}"
        render json: { errors: [{ message: 'Unauthorized' }] }, status: :unauthorized
        return nil
      end
    rescue JWT::DecodeError => e
      Rails.logger.warn "JWT Decode Error: #{e.message}"
      render json: { errors: [{ message: 'Invalid token' }] }, status: :unauthorized
      return nil
    rescue JWT::ExpiredSignature
      Rails.logger.warn "JWT Expired: #{token}"
      render json: { errors: [{ message: 'Token expired' }] }, status: :unauthorized
      return nil
    end
  end
end
