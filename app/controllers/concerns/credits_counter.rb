module CreditsCounter
  extend ActiveSupport::Concern

  included do |base|
  end

  def total_credits(user)
    user.charges
        .where("amount_refunded is null or amount_refunded = 0")
        .inject(0) { |sum, item| sum + item.metadata.fetch("credits").to_i }
  end

  def total_used_credits(user)
    user.conversations.inject(0) { |sum, item| sum + used_credits(item) }
  end

  def left_credits(user)
    credits = total_credits(user) - total_used_credits(user) + (ENV.fetch('FREEMIUM_CREDITS') { 0 }).to_i

    credits = 0 if credits < 0
    return credits
  end

  def used_credits(conversation)
    conversation.ai_calls.succeeded_ai_calls.sum(:cost_credits)
  end

  module ClassMethods
  end
end
