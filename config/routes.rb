Rails.application.routes.draw do
  mount_devise_token_auth_for 'User', at: 'auth', controllers:
    { omniauth_callbacks: 'users/omniauth_callbacks' }

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root "users/sessions#new"

  post 'checkout', to: 'payment#checkout', as: 'checkout'
  get 'billing', to: 'payment#billing', as: 'billing'

  # 跨域预检请求
  match '*all', controller: 'application', action: 'cors_preflight_check', via: [:options]

  namespace :api do
    namespace :v1 do
      resources :info do
        collection do
          get 'models' => "info#models", as: 'models'
        end
      end
    end
  end
end
