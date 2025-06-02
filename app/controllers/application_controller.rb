class ApplicationController < ActionController::API
  include DeviseTokenAuth::Concerns::SetUserByToken
  include Pundit::Authorization

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  rescue_from StandardError, with: :log_error_and_respond

  before_action :cors_set_access_control_headers
  before_action :set_locale

  render :json

  @@maintenance = false

  def cors_preflight_check
    # if request.method == 'OPTIONS'
    render status: 200
    # end
  end

  private

  def maintenance_mode?
    @@maintenance
  end

  def maintenance_mode!
    puts @@maintenance
    @@maintenance = true# if current_user.email == ENV.fetch('ADMIN_USER_EMAIL')
  end

  def check_if_maintenance_mode
    if maintenance_mode?
      render json: {
        error: "Maintenance in progress. Please try again in 10 minutes."
      }, status: 503
    end
  end

  def user_not_authorized
    # fail 'User not authorized'
    render json: {
      message: 'You do not has enough credits'
    }.to_json, status: 403
  end

  def cors_set_access_control_headers
    response.headers['Access-Control-Allow-Origin'] = '*'

    # 设置运行浏览器发送的 HTTP 头
    response.headers['Access-Control-Allow-Headers'] = 'Origin, Content-Type, Accept, Authorization, Token, Auth-Token, Email, X-User-Token, X-User-Email'

    # 设置浏览器可以读取到的 HTTP 头
    response.headers['Access-Control-Expose-Headers'] = 'Authorization'

    response.headers['Access-Control-Allow-Methods'] = 'POST, GET, PUT, PATCH, DELETE, OPTIONS'
    #response.headers['Access-Control-Max-Age'] = '1728000'
  end

  def set_locale
    I18n.locale = params[:locale] || I18n.default_locale
  end

  def log_error_and_respond(exception)
    # 将错误信息记录到数据库
    ErrorLog.create(
      origin_type: 0,
      error_type: exception.class.to_s,
      message: exception.message,
      backtrace: exception.backtrace.join("\n"),
      controller_name: params[:controller],
      action_name: params[:action],
      user_email: current_user&.email
    )

    # 返回通用错误响应
    render json: { error: 'Internal Server Error' }, status: 500
  end
end
