class PaymentController < ApplicationController
  before_action :authenticate_user!

  def billing
    billing = current_user.payment_processor.billing_portal
    redirect_to billing.url, allow_other_host: true, status: :see_other
  end

  def checkout
    current_user.set_payment_processor :stripe

    params[:success_url] ||= root_url

    fail 'mode cannot be null' unless params[:mode]

    case params[:mode]
    when 'payment'
      fail 'price_id cannot be null' unless params[:price_id]

      checkout_session = current_user.payment_processor.checkout(
        mode: params[:mode],
        locale: I18n.locale,
        line_items: [{
                       price: params[:price_id],
                       quantity: 1
                     }],
        success_url: params[:success_url],
        cancel_url: params[:cancel_url],
        payment_intent_data: {
          metadata: {
            credits: 1
          }
        },
        metadata: {
          credits: 1
        }
      )

    when 'subscription'
      fail 'product_id cannot be null' unless params[:product_id]

      checkout_session = current_user.payment_processor.checkout(
        mode: params[:mode],
        locale: I18n.locale,
        line_items: [{
                       quantity: 1,
                       price_data: {
                         recurring: {
                           interval: 'month',
                           interval_count: 1
                         },
                         unit_amount_decimal: '1000',
                         currency: 'usd',
                         product: params[:product_id]
                       }
                     }],
        success_url: params[:success_url],
        cancel_url: params[:cancel_url],
        subscription_data: {
          trial_period_days: ENV.fetch('TRIAL_PERIOD_DAYS'),
          metadata: {
            pay_name: "base", # Optional. Overrides the Pay::Subscription name attribute
            credits: 1
          },
        },
        metadata: {
          credits: 1
        }
      )
    end

    redirect_to checkout_session.url, allow_other_host: true, status: :see_other
  end
end