Rails.application.routes.draw do
  mount_devise_token_auth_for 'User', at: 'auth', controllers:
    { omniauth_callbacks: 'users/omniauth_callbacks' }

  # require 'sidekiq/web'
  # authenticate :user, lambda { |u| u.admin? } do
  #   mount Sidekiq::Web => '/sidekiq'
  # end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root "users/sessions#new"

  post 'token', to: 'users/omniauth_callbacks#token'
  post 'google_onetap_token', to: 'users/google_one_tap#token'

  post 'stripe_checkout', to: 'payment#stripe_checkout', as: 'stripe_checkout'
  get 'stripe_billing', to: 'payment#stripe_billing', as: 'billing'
  post 'paddle_customer', to: 'payment#paddle_customer', as: 'paddle_customer'
  get 'charges_history', to: 'payment#charges_history', as: 'charges_history'
  post 'creem_checkout', to: 'payment#creem_checkout', as: 'creem_checkout'
  post 'creem_callback', to: 'payment#creem_callback', as: 'creem_callback'

  # 跨域预检请求
  match '*all', controller: 'application', action: 'cors_preflight_check', via: [:options]

  namespace :api do
    namespace :v1 do
      get 'user_info',to: 'info#user_info'
      get 'dynamic_urls',to: 'info#dynamic_urls'
      get 'payment_info',to: 'info#payment_info'
      post 'log_client_error', to: 'info#log_client_error'
      get 'active_subscription_info', to: 'info#active_subscription_info', as: 'active_subscription_info'

      post 'gen_image', to: 'ai#gen_image'
      post 'gen_video', to: 'ai#gen_video'
      get 'ai_call_info', to: 'ai#ai_call_info'

      resources :info do
        collection do

        end
      end

      namespace :admin do
        resources :dashboard do
          collection do
            get 'staticstics_info' => 'dashboard#statistics_info'
            get 'ai_call_info' => 'dashboard#ai_call_info'
            get 'error_log', to: 'dashboard#error_log'
            get 'users', to: 'dashboard#users'
            get 'pay_webhooks', to: 'dashboard#pay_webhooks'
            post 'rerun_pay_webhook', to: 'dashboard#rerun_pay_webhook'
            get 'pay_orders', to: 'dashboard#pay_orders'
            get 'origin_orders', to: 'dashboard#origin_orders'
            post 'maintenance_mode', to: 'dashboard#maintenance_mode'
          end
        end
      end

      resources :tools do
        collection do
          get :published
          get :unpublished
          get :search
          get :tool_alternatives
          get :tag_tools
          get :monthly_tools
        end

        member do
          post :publish
          post :unpublish
        end
      end

      resources :tags do
        member do
          get :tools
        end
      end

      resources :scraped_infos do
        collection do
          get :tdh
          get :website
        end
      end
    end
  end
end
