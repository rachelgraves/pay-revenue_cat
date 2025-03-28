# # frozen_string_literal: true

Pay::Revenuecat::Engine.routes.draw do
  get "/test", to: "pay/revenuecat/test#index"
  resources :posts
end
