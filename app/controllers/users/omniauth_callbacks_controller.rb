class Users::OmniauthCallbacksController < DeviseTokenAuth::OmniauthCallbacksController

  # def omniauth_success
  #   super
  # end

  # def redirect_callbacks
  #   super
  # end

  def render_data_or_redirect(message, data, user_data = {})
    if message == 'deliverCredentials'
      redirect_to ENV.fetch('REDIRECT_SUCCESS_URL'), allow_other_host: true
    elsif message == 'authFailure'
      redirect_to ENV.fetch('REDIRECT_FAIL_URL'), allow_other_host: true
    end
  end
end