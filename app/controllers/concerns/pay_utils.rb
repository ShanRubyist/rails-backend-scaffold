module PayUtils
  extend ActiveSupport::Concern

  included do |base|
  end

  def has_active_subscription?(user)
    # latest_subscription = user.subscriptions.order('updated_at').last
    # latest_subscription.active?

    user.subscriptions.where(status: 'active').count > 0
  end

  def active_subscriptions(user)
    user.subscriptions.where(status: 'active').order('updated_at')
  end

  module ClassMethods
  end
end
