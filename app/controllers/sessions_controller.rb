class SessionsController < ApiBaseController
  skip_before_action :authenticate_user_from_token!

  def create
    auth_key = Devise.authentication_keys.first

    @user = User.find_for_database_authentication(auth_key => signin_params[auth_key])
    if @user && @user.valid_password?(signin_params[:password])
      sign_in :user, @user
      render json: @user, serializer: SessionSerializer, meta: {}
    else
      warden.custom_failure!
      render json: nil, serializer: SessionSerializer, meta: { errors: { auth_key => ["Invalid #{auth_key} and/or password"] }}, status: :unprocessable_entity
    end
  end

  private

  def signin_params
    params.require(:signin).permit(:username, :email, :password)
  end
end
