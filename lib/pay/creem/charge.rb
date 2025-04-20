module Pay
  module Creem
    class Billable
      attr_reader :pay_customer

      # delegate :processor_id,
      #          :processor_id?,
      #          :email,
      #          :customer_name,
      #          :card_token,
      #          to: :pay_customer

      def initialize(pay_customer)
        @pay_customer = pay_customer
      end
    end

    class Charge
      def self.sync(record)
        order_id = record.event['object']['order']['id']

        # Skip loading the latest charge details from the API if we already have it
        @client ||= Faraday.new(url: ENV.fetch('CREEM_BASE_URL'))
        resp = @client.get('/v1/transactions/search?order_id=' + order_id) do |req|
          req.headers['x-api-key'] = ENV.fetch('CREEM_API_KEY')
          req.headers['Content-Type'] = 'application/json'
        end

        if resp.success?
          object = JSON.load(resp.body)

          fail 'this order has multi transactions ' if object['items'].length > 1
          object = object['items'].first

          # Ignore charges without a Customer
          return if object['customer']&.blank?

          pay_customer = creem_customer(object['customer'])
          return unless pay_customer

          if record.event_type == "checkout.completed"
            # Ignore transactions that aren't completed
            return unless record.event['object']['status'] == "completed"

            # # Ignore transactions that are payment method changes
            # # But update the customer's payment method
            # if object.origin == "subscription_payment_method_change"
            #   Pay::PaddleBilling::PaymentMethod.sync(pay_customer: pay_customer, attributes: object.payments.first)
            #   return
            # end

            attrs = {
              amount: object['amount'],
              # created_at: object['created_at'],
              currency: object['currency'],
              metadata: object.merge(record.event['object']['metadata'].to_h),
              # subscription: pay_customer.subscriptions.find_by(processor_id: object.subscription.id)
            }

            # if object.payment
            #   case object.payment.method_details.type.downcase
            #   when "card"
            #     attrs[:payment_method_type] = "card"
            #     attrs[:brand] = details.card.type
            #     attrs[:exp_month] = details.card.expiry_month
            #     attrs[:exp_year] = details.card.expiry_year
            #     attrs[:last4] = details.card.last4
            #   when "paypal"
            #     attrs[:payment_method_type] = "paypal"
            #   end
            #
            #   # Update customer's payment method
            #   Pay::PaddleBilling::PaymentMethod.sync(pay_customer: pay_customer, attributes: object.payments.first)
            # end

            # Update or create the charge
            if (pay_charge = pay_customer.charges.find_by(processor_id: object['order']))
              pay_charge.with_lock do
                pay_charge.update!(attrs)
              end
              pay_charge
            else
              Pay::Charge.create!(attrs.merge(processor_id: object['order'], customer_id: pay_customer.id))
            end
          elsif record.event_type == "refund.created"
            return unless record.event['object']['status'] == "succeeded"

            attrs = { amount_refunded: object['refunded_amount'] }

            if (pay_charge = pay_customer.charges.find_by(processor_id: object['order']))
              pay_charge.with_lock do
                pay_charge.update!(attrs)
              end
              pay_charge
            end
          end

          record.destroy
        else
          fail 'creem callback fail:' + resp.inspect
        end
      end

      private

      def self.creem_customer(customer_id)
        customer = Pay::Customer.find_by(processor: :creem, processor_id: customer_id)
        if customer
          return customer
        else
          @client ||= Faraday.new(url: ENV.fetch('CREEM_BASE_URL'))
          resp = @client.get('/v1/customers?customer_id=' + customer_id) do |req|
            req.headers['x-api-key'] = ENV.fetch('CREEM_API_KEY')
            req.headers['Content-Type'] = 'application/json'
          end

          if resp.success?
            object = JSON.load(resp.body)
            owner = User.find_by(email: object['email'])
            return unless owner
            Pay::Customer.create!(processor: :creem, processor_id: customer_id, owner: owner)
          end
        end
      end

    end
  end
end




