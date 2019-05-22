require 'sidekiq/web'
Rails.application.routes.draw do
  mount ShopifyApp::Engine, at: '/'

  devise_for :users,
             path: "users",
             only: :none,
             controllers: { sessions: "users/sessions"}
  devise_for :admins,
             path: "admins",
             class_name: "PR::Common::Models::Admin",
             controllers: { sessions: "admins/sessions" }

  mount Sidekiq::Web => '/sidekiq'

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
