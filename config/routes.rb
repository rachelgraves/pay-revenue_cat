# # frozen_string_literal: true

Pay::Revenuecat::Engine.routes.draw do
  post "webhooks/revenuecat", to: "pay/webhooks/revenuecat#create"
end
