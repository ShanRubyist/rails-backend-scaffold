class UsageController < ApplicationController
  before_action :authenticate_user!
  before_action :check_if_maintenance_mode
  around_action :check_credits

  include CreditsCounter
  include DistributedLock

  def credits_enough?(current_locked_credits, current_cost_credits)
    raise NotImplementedError, "You must define #current_cost_credits in #{self.class}" unless defined?(:current_cost_credits)
    (left_credits(current_user) >= (current_cost_credits + current_locked_credits)) || subscription_valid?
  end

  private

  def has_payment?
    ENV.fetch('HAS_PAYMENT') == 'true' ? true : false
  end

  def account_confirmed?
    current_user.confirmed?
  end

  def subscription_valid?
    current_user.subscriptions.last&.active?
  end

  def check_credits
    locked_credits_key = "users_locked_credits:#{current_user.id}"

    with_redis_lock(current_user.id) do
      if credits_enough?(current_locked_credits(locked_credits_key), current_cost_credits)
        reserved, _ = reserve_locked_credits(locked_credits_key, current_cost_credits)
        raise "lock credit fail" unless reserved.is_a?(Integer)
      else
        render json: {
          message: 'You do not has enough credits'
        }.to_json, status: 403
        return
      end
    end

    yield

    release_locked_credits(locked_credits_key, current_cost_credits) rescue nil
  end

  def current_locked_credits(locked_credits_key)
    redis_client.get(locked_credits_key).to_i
  end

  def reserve_locked_credits(locked_credits_key, amount)
    redis_client.multi do |pipeline|
      pipeline.incrby(locked_credits_key, amount) # 增加锁定积分
      pipeline.expire(locked_credits_key, 300) # 5分钟后自动过期（单位：秒）
    end
  end

  def release_locked_credits(locked_credits_key, amount)
    release_script = <<-LUA
      local key = KEYS[1]
      local amount = tonumber(ARGV[1])
      local current = tonumber(redis.call('GET', key)) or 0
    
      if current >= amount then
        redis.call('DECRBY', key, amount)
        -- 此处可触发数据库的永久扣减记录
        return true
      end
      return false
    LUA
    redis_client.eval(release_script, [locked_credits_key], [amount])
  end

  # TODO: 需要编辑
  def current_cost_credits
    case params[:model]
    when nil
      1
    when 'black-forest-labs/flux-schnell'
      1
    when 'black-forest-labs/flux-dev'
      10
    when 'black-forest-labs/flux-pro'
      20
    end
  end
end