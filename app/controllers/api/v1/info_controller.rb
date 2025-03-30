class Api::V1::InfoController < ApplicationController
  before_action :authenticate_user!, only: [:user_info, :active_subscription_info]

  include CreditsCounter
  include PayUtils

  def user_info
    render json: {
      id: current_user.id,
      email: current_user.email,
      name: current_user.name,
      image: current_user.image,
      provider: current_user.provider,
      created_at: current_user.created_at,
      updated_at: current_user.updated_at,
      credits: left_credits(current_user),
    }.to_json
  end

  def payment_info
    render json: {
      has_payment: ENV.fetch('HAS_PAYMENT') == 'true' ? true : false,
      payment_processor: ENV.fetch('PAYMENT_PROCESSOR'),
      paddle_billing_environment: ENV.fetch('PADDLE_BILLING_ENVIRONMENT'),
      paddle_billing_client_token: ENV.fetch('PADDLE_BILLING_CLIENT_TOKEN'),
      price_1: ENV.fetch('PRICE_1'),
      price_1_credits: ENV.fetch('PRICE_1_CREDIT'),
      price_2: ENV.fetch('PRICE_2'),
      price_2_credits: ENV.fetch('PRICE_2_CREDIT'),
      price_3: ENV.fetch('PRICE_3'),
      price_3_credits: ENV.fetch('PRICE_3_CREDIT'),
    }.to_json
  end

  def active_subscription_info
    render json: {
      has_active_subscription: has_active_subscription?(current_user),
      active_subscriptions: active_subscriptions(current_user).map do |sub|
        {
          id: sub.processor_id,
          name: sub.name,
          plan: sub.processor_plan,
          status: sub.status,
          current_period_start: sub.current_period_start.to_s,
          current_period_end: sub.current_period_end.to_s,
          trial_ends_at: sub.trial_ends_at.to_s,
          ends_at: sub.ends_at.to_s,
          created_at: sub.created_at.to_s,
          updated_at: sub.updated_at.to_s,
        }
      end
    }
  end

  def dynamic_urls
    render json: previous_month_range.map { |i| { loc: '/month/' + i, _i18nTransform: true } }
  end

  def log_client_error
    # 从请求中获取错误信息
    error_params = params.require(:error).permit(:origin_type, :error_type, :message, :backtrace, :controller_name, :action_name, :user_email)

    # 创建错误日志
    ErrorLog.create(
      origin_type: error_params[:origin_type],
      error_type: error_params[:error_type],
      message: error_params[:message],
      backtrace: error_params[:backtrace],
      controller_name: error_params[:controller_name],
      action_name: error_params[:action_name],
      user_email: error_params[:user_email]
    )

    # 返回成功响应
    render json: { message: 'Error logged successfully' }, status: 201
  end

  private
  def previous_month_range(count: 5)
    current_month = Time.current.beginning_of_month
    (1..count).map do |i|
      (current_month - i.months).strftime("%Y-%m") # 格式化为 "2023-07"
    end
  end
end