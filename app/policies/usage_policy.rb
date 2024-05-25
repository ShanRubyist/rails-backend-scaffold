class UsagePolicy < ApplicationPolicy
  include CreditsCounter

  def initialize(user, _record)
    @user = user
  end

  def create?
    return true if !has_payment? || credits_enough? || subscription_valid?
  end

  private

  def has_payment?
    ENV.fetch('HAS_PAYMENT') == 'true' ? true : false
  end

  def account_confirmed?
    @user.confirmed?
  end

  def subscription_valid?
    @user.subscriptions.last&.active?
  end

  def credits_enough?
    left_credits(@user) > 0
  end
end
