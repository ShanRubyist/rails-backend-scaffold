# paddle_billing vs stripe
# 1、paddle_billing 需要手动使用 current_user.payment_processor.customer 来创建customer
# 2、paddle_billing 的发送短信和refund 都是通过webhook来自己补充的 app/webhooks
# 3、paddle_billing 的 metadata 和refund 是通过猴子补丁的方式，打开Pay::PaddleBilling::Charge类重写sync方式实现的 lib/pay/paddle_billing/charge.rb

class PaymentController < ApplicationController
  before_action :check_if_maintenance_mode, only: [:stripe_checkout, :creem_checkout, :paddle_customer]
  before_action :authenticate_user!, except: [:creem_callback]

  include PayUtils

  def stripe_billing
    authorize :payment
    current_user.set_payment_processor :stripe
    billing = current_user.payment_processor.billing_portal
    redirect_to billing.url, allow_other_host: true, status: :see_other
  end

  def stripe_checkout
    current_user.set_payment_processor :stripe

    # fail 'mode cannot be null' unless params[:mode]
    params[:mode] ||= 'payment'
    params[:success_url] ||= params[:success_url]

    case params[:mode]
    when 'payment'
      checkout_session = stripe_checkout_payment(current_user, params[:price_id], params[:success_url], params[:cancel_url])
    when 'subscription'
      if has_active_subscription?(current_user)
        render json: {
          message: "Your already has a active subscription"
        }.to_json, status: 500

        return
      end
      checkout_session = stripe_checkout_subscription(current_user, params[:price_id], params[:success_url], params[:cancel_url])
    end

    # redirect_to checkout_session.url, allow_other_host: true, status: :see_other
    render json: {
      url: checkout_session.url
    }
  end

  def creem_checkout
    # current_user.set_payment_processor :creem

    # fail 'mode cannot be null' unless params[:mode]
    params[:mode] ||= 'payment'
    params[:success_url] ||= params[:success_url]

    # case params[:mode]
    # when 'payment'
    @client ||= Faraday.new(url: ENV.fetch('CREEM_BASE_URL'))
    resp = @client.post('/v1/checkouts') do |req|
      req.headers['x-api-key'] = ENV.fetch('CREEM_API_KEY')
      req.headers['Content-Type'] = 'application/json'
      req.body = {
        success_url: params[:success_url],
        product_id: params[:price_id],
        customer: {
          "email": current_user.email
        },
        metadata: {
          request_id: SecureRandom.uuid,
          userId: current_user.id,
          credits: credit_of_price(params[:price_id]),
        }
      }.to_json
    end
    # when 'subscription'
    #   if has_active_subscription?(current_user)
    #     render json: {
    #       message: "Your already has a active subscription"
    #     }.to_json, status: 500
    #
    #     return
    #   end
    #   checkout_session = stripe_checkout_subscription(current_user, params[:price_id], params[:success_url], params[:cancel_url])
    # end

    render json: {
      url: JSON.load(resp.body)['checkout_url']
    }
  end

  def creem_callback
    if valid_signature?(request.headers["creem-signature"])
      record = Pay::Webhook.create!(processor: :creem, event_type: params[:eventType], event: JSON.parse(request.body.read))
      PayProcessJob.perform_later(record)
      head :ok
    else
      head :bad_request
    end
  end

  def paddle_customer
    current_user.set_payment_processor :paddle_billing

    begin
      # Create the customer on Paddle
      current_user.payment_processor.customer
      render json: {}.to_json, status: 200
    rescue Pay::PaddleBilling::Error
      # current_user.payment_processor.processor_id= Paddle::Customer.list(email: current_user.email).data.first.id if payment_processor.processor_id.nil?
      render json: {
        message: "Your request was a conflict.customer \"#{current_user.email}\" already exists"
      }.to_json, status: 500
    rescue => e
      render json: {
        message: e.full_message.to_s
      }.to_json, status: 500
    end
  end

  def charges_history
    params[:page] ||= 1
    params[:per] ||= 20

    charges = current_user.charges.order("created_at desc").page(params[:page].to_i).per(params[:per].to_i)

    render json: {
      total: charges.total_count,
      current_page: charges.current_page,
      total_pages: charges.total_pages,
      charges_history: charges.map do |charge|
        {
          I18n.t('charges_history.created_at') => charge.created_at.to_s,
          I18n.t('charges_history.updated_at') => charge.updated_at.to_s,
          I18n.t('charges_history.subscription_id') => charge.subscription_id || '-',
          I18n.t('charges_history.processor') => current_user.pay_customers.find_by(id: charge.customer_id).processor,
          I18n.t('charges_history.processor_id') => charge.processor_id,
          I18n.t('charges_history.amount') => charge.amount / 100.0,
          I18n.t('charges_history.currency') => charge.currency,
          I18n.t('charges_history.application_fee_amount') => (charge.application_fee_amount || 0) / 100.0,
          I18n.t('charges_history.amount_refunded') => (charge.amount_refunded || 0) / 100.0,
          I18n.t('charges_history.credits') => charge.metadata['credits'] || 0,
        }
      end
    }
  end

  def subscription_history

  end

  private

  def valid_signature?(signature)
    return true if Rails.env.development?
    return false if signature.blank?
    hmac = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), ENV.fetch('CREEM_SIGNING_SECRET'), request.body.read)
    hmac == signature
  end

  def stripe_checkout_payment(user, price_id, success_url, cancel_url)
    fail 'price_id cannot be null' unless price_id

    checkout_session = user.payment_processor.checkout(
      mode: 'payment',
      locale: I18n.locale,
      line_items:
        [{
           price: price_id,
           quantity: 1
         }],
      success_url: success_url,
      cancel_url: cancel_url,
      payment_intent_data: {
        metadata: {
          credits: credit_of_price(price_id)
        }
      }
    )

    return checkout_session
  end

  def stripe_checkout_subscription(user, price_id, success_url, cancel_url)
    fail 'price_id cannot be null' unless price_id

    checkout_session = user.payment_processor.checkout(
      mode: 'subscription',
      locale: I18n.locale,
      line_items:
        [{
           price: price_id,
           quantity: 1
         }],
      success_url: success_url,
      cancel_url: cancel_url,
      subscription_data: {
        trial_period_days: ENV.fetch('TRIAL_PERIOD_DAYS'),
        metadata: {
          pay_name: "base", # Optional. Overrides the Pay::Subscription name attribute
        },
      }
    )
    return checkout_session
  end

  def credit_of_price(price_id)
    credit = case price_id
             when ENV.fetch('PRICE_1')
               ENV.fetch('PRICE_1_CREDIT')
             when ENV.fetch('PRICE_2')
               ENV.fetch('PRICE_2_CREDIT')
             when ENV.fetch('PRICE_3')
               ENV.fetch('PRICE_3_CREDIT')
             end

    return credit.to_i
  end
end
