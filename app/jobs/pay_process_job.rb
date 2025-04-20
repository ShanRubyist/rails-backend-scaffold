require_relative '../../lib/pay/creem/charge'

class PayProcessJob < ApplicationJob
  queue_as :pay_queue

  def perform(event)
    Pay::Creem::Charge.sync(event)
  end
end