class Api::V1::Admin::DashboardController < Api::V1::AdminController
  def maintenance_mode
    maintenance_mode!

    if maintenance_mode?
      render json: {
      }, status: :ok
    else
      render status: 503
    end
  end

  def statistics_info
    total_users = User.all.size
    total_paid_users = '-'
    total_generated_user = User.joins(conversations: :ai_calls).distinct.count
    total_images = AiCall.all.size
    total_paid_dollar = '-'
    total_paid_credits = 0
    total_cost_dollar = '-'
    total_cost_credits = AiCall.where("ai_calls.data->>'status' = ?", 'success').sum(:cost_credits)
    total_left_dollar = '-'
    total_left_credits = total_paid_credits - total_cost_credits

    today_newly_users = User.where("DATE(created_at) = ?", Date.today).count
    today_paid_users = '-'
    today_generated_users = User.joins(conversations: :ai_calls)
                                .where(ai_calls: { created_at: Time.current.beginning_of_day..Time.current.end_of_day })
                                .distinct
                                .count
    today_images = AiCall.where(created_at: Time.current.beginning_of_day..Time.current.end_of_day).count
    today_paid_dollar = '-'
    today_paid_credits = '-'
    today_cost_dollar = '-'
    today_cost_credits = AiCall.succeeded_ai_calls
                               .where(created_at: Time.current.beginning_of_day..Time.current.end_of_day)
                               .sum(:cost_credits)

    freeium_total_credits = total_users * (ENV.fetch('FREEMIUM_CREDITS') { 0 }).to_i
    freeium_cost_credits = total_cost_credits
    freeium_left_credits = freeium_total_credits - freeium_cost_credits
    freeium_run_out_users = '-'
    # User.joins(:replicated_calls)
    #                          .where("replicated_calls.data->>'status' = ?", 'succeeded')
    #                          .group('users.id')
    #                          .having('COUNT(*) >= ?', 0)
    #                       .select("users.id, users.email, COUNT(*) as successful_call_count")

    user_top_paid_dollar = '-'
    user_top_paid_credits = '-'
    user_top_cost_dollar = '-'
    user_top_cost_credits = User.joins(conversations: :ai_calls)
                                .group("users.id")
                                .select("users.id, sum(cost_credits) as cost_credits")
                                .order('cost_credits desc')
                                .limit(1)
                                .first
                              &.cost_credits

    user_top_generated_images = User.joins(conversations: :ai_calls)
                                    .group("users.id")
                                    .select("users.id, users.email, COUNT(*) as call_count")
                                    .order("call_count desc")
                                    .limit(1)
                                    .first
                                  &.call_count
    render json: {
      total_users: total_users,
      total_paid_users: total_paid_users,
      total_generated_user: total_generated_user,
      total_images: total_images,
      total_paid_dollar: total_paid_dollar,
      total_paid_credits: total_paid_credits,
      total_cost_dollar: total_cost_dollar,
      total_cost_credits: total_cost_credits,
      total_left_dollar: total_left_dollar,
      total_left_credits: total_left_credits,
      today_newly_users: today_newly_users,
      today_paid_users: today_paid_users,
      today_generated_users: today_generated_users,
      today_images: today_images,
      today_paid_dollar: today_paid_dollar,
      today_paid_credits: today_paid_credits,
      today_cost_dollar: today_cost_dollar,
      today_cost_credits: today_cost_credits,
      freeium_total_credits: freeium_total_credits,
      freeium_cost_credits: freeium_cost_credits,
      freeium_left_credits: freeium_left_credits,
      freeium_run_out_users: freeium_run_out_users,
      user_top_paid_dollar: user_top_paid_dollar,
      user_top_paid_credits: user_top_paid_credits,
      user_top_cost_dollar: user_top_cost_dollar,
      user_top_cost_credits: user_top_cost_credits,
      user_top_generated_images: user_top_generated_images
    }.to_json
  end

  def ai_call_info
    params[:page] ||= 1
    params[:per] ||= 20

    ai_calls = AiCall
                 .order("created_at desc")
                 .page(params[:page].to_i)
                 .per(params[:per].to_i)

    result = ai_calls.map do |item|
      {
        input_media: (
          item.input_media.map do |media|
            url_for(media)
          end
        ),
        generated_media: (
          item.generated_media.map do |media|
            url_for(media)
          end
        ),
        prompt: item.prompt,
        status: item.status,
        input: item.input,
        data: item.data,
        created_at: item.created_at,
        cost_credits: item.cost_credits,
        system_prompt: item.system_prompt,
        business_type: item.business_type
      }
    end

    render json: {
      total: ai_calls.total_count,
      histories: result
    }
  end

  def error_log
    params[:page] ||= 1
    params[:per] ||= 20

    error_log = ErrorLog
                  .order("created_at desc")
                  .page(params[:page].to_i)
                  .per(params[:per].to_i)

    render json: {
      total: error_log.total_count,
      error_log: error_log.map do |log|
        {
          # id: log.id,
          type: log.error_type,
          message: log.message,
          controller_name: log.controller_name,
          action_name: log.action_name,
          email: log.user_email,
          created_at: log.created_at,
        }
      end
    }
  end

  def users
    params[:page] ||= 1
    params[:per] ||= 20

    users = User
              .order("created_at desc")
              .page(params[:page].to_i)
              .per(params[:per].to_i)

    render json: {
      total: users.total_count,
      users: users.map do |user|
        {
          email: user.email,
          nickname: user.nickname,
          name: user.name,
          provider: user.provider,
          created_at: user.created_at,
        }
      end
    }
  end

  def pay_webhooks
    params[:page] ||= 1
    params[:per] ||= 20

    webhooks = Pay::Webhook
                 .order("created_at desc")
                 .page(params[:page].to_i)
                 .per(params[:per].to_i)

    render json: {
      total: webhooks.total_count,
      webhooks: webhooks.map do |webhook|
        {
          id: webhook.id,
          processor: webhook.processor,
          event_type: webhook.event_type,
          event: webhook.event,
          created_at: webhook.created_at,
        }
      end
    }
  end

  def rerun_pay_webhook
    # 只支持creem
    id = params[:id]
    fail 'id can not be empty' unless id

    webhook = Pay::Webhook.find_by(id: id)
    job = PayProcessJob.perform_later(webhook)

    render json: {
      message: 'successfully_enqueued'
    }
  end

  def pay_orders
    params[:page] ||= 1
    params[:per] ||= 20
    order_id = params[:order_id]
    email = params[:email]

    order_list = Pay::Charge
    order_list = Pay::Charge.where(processor_id: order_id) if !order_id.blank?

    orders = order_list
               .joins('INNER JOIN pay_customers ON pay_charges.customer_id = pay_customers.id')
               .joins('INNER JOIN users ON pay_customers.owner_id = users.id AND pay_customers.owner_type = \'User\'')

    orders = orders.where("users.email = ?", email) if !email.blank?

    orders = orders
               .order("pay_charges.created_at desc")
               .page(params[:page].to_i)
               .per(params[:per].to_i)
               .select('pay_charges.*, users.email AS user_email')

    render json: {
      total: orders.total_count,
      orders: orders.map do |order|
        {
          amount: order.amount.to_i,
          currency: order.currency,
          amount_refunded: order.amount_refunded.to_i,
          application_fee_amount: order.application_fee_amount.to_i,
          metadata: order.metadata,
          order_id: order.processor_id,
          customer_email: order.user_email,
          created_at: order.created_at,
        }
      end
    }
  end

  def origin_orders
    # TODO: 支持手动补偿
    # 只支持creem
    order_id = params[:order_id]
    fail 'order id can not be empty' unless order_id

    render json: {
      orders: get_order_form_creem(order_id)
    }
  end

  private

  def get_order_form_creem(order_id)
    client ||= Faraday.new(url: ENV.fetch('CREEM_BASE_URL'))
    resp = client.get('/v1/transactions/search?order_id=' + order_id) do |req|
      req.headers['x-api-key'] = ENV.fetch('CREEM_API_KEY')
      req.headers['Content-Type'] = 'application/json'
    end

    if resp.success?
      JSON.load(resp.body)
    else
      fail 'Get order from creem fail:' + resp.inspect
    end
  end
end

