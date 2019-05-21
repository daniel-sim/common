require 'sidekiq/web'
Rails.application.routes.draw do
  devise_for :admins,
             class_name: "PR::Common::Models::Admin",
             controllers: { sessions: "admins/sessions" }

  mount Sidekiq::Web => '/sidekiq'

  resources :sessions, only: :create
  resources :signups,  only: :create
  resources :forgotten_password_requests, only: :create
  resources :passwords, only: [:create, :update]

  namespace :promo_codes do
    get 'check/:promo_code', action: :check
  end

  namespace "admin" do
    resources :promo_codes
  end

  post 'shops/callback'

  post 'webhooks', to: 'webhooks#receive'
  post 'webhooks/:topic', to: 'webhooks#receive'

  resources :charges,      only: [:create] do
    collection do
      get :callback
    end
  end
end
