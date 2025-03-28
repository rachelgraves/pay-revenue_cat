# # frozen_string_literal: true

Pay::Revenuecat::Engine.routes.draw do
  get "/test", to: "test#index"
end
