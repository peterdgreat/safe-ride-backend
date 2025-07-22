class ApplicationController < ActionController::API
  include Pundit::Authorization
  include ErrorHandler

  def set_current_user
    puts "set_current_user called"
    if request.headers['Authorization'].present?
      puts "All Request Headers: #{request.headers.inspect}"
      token = request.headers['Authorization'].split(' ').last
      begin
        puts "Devise JWT Secret Key: #{Rails.application.credentials.devise_jwt_secret_key!}"
        decoded_token = JWT.decode(token, Rails.application.credentials.devise_jwt_secret_key!, true, algorithm: 'HS256')
        user_id = decoded_token[0]['sub']
        puts "User ID from token: #{user_id}"
        @current_user = User.find(user_id)
        puts "Current User after find: #{@current_user.inspect}"
      rescue JWT::DecodeError => e
        puts "JWT Decode Error: #{e.message}"
        @current_user = nil
      rescue ActiveRecord::RecordNotFound => e
        puts "User not found: #{e.message}"
        @current_user = nil
      end
    else
      puts "Authorization header not present"
      @current_user = nil
    end
  end

  def current_user
    @current_user
  end
end
