# # frozen_string_literal: true

Pay::RevenueCat::Engine.routes.draw do
  post "webhooks/revenue_cat", to: "pay/webhooks/revenue_cat#create"
end
