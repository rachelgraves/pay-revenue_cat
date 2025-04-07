class Account < ApplicationRecord
  pay_customer default_payment_processor: :revenuecat
end
