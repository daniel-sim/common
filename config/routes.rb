require 'sidekiq/web'
Rails.application.routes.draw do
  devise_for :users, only: []

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

  get 'user_admin/search'
  post 'user_admin/refunds', to: 'user_admin#make_refund'

  post 'webhooks', to: 'webhooks#receive'
  post 'webhooks/:topic', to: 'webhooks#receive'

  resources :charges,      only: [:create] do
    collection do
      get :callback
    end
  end
end
