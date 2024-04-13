Rails.application.routes.draw do
  mount_devise_token_auth_for 'User', at: 'auth', controllers:
    { omniauth_callbacks: 'users/omniauth_callbacks' }

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root "users/sessions#new"

  post 'checkout', to: 'payment#checkout', as: 'checkout'
  get 'billing', to: 'payment#billing', as: 'billing'
end
