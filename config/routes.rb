require 'sidekiq/web'
Rails.application.routes.draw do
  devise_for :users, only: :none # see https://github.com/plataformatec/devise/issues/4580
  devise_for :admins,
             class_name: "PR::Common::Models::Admin",
             controllers: { sessions: "admins/sessions" }

  mount Sidekiq::Web => '/sidekiq'

  controller :sessions do
    get 'login' => :new, :as => :login
    post 'login' => :create, :as => :authenticate
    get 'auth/shopify/callback' => :callback
    get 'logout' => :destroy, :as => :logout
  end

  namespace :webhooks do
    post ':type' => :receive
  end

  resources :signups,  only: :create
  resources :forgotten_password_requests, only: :create
  resources :passwords, only: [:create, :update]

  namespace :promo_codes do
    get 'check/:promo_code', action: :check
  end

  namespace "admin" do
    resources :promo_codes
  end

  post 'webhooks', to: 'shopify_app/webhooks#receive'
  post 'webhooks/:topic', to: 'shopify_app/webhooks#receive'

  resources :charges,      only: [:create] do
    collection do
      get :callback
    end
  end
end
