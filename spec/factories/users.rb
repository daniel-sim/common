FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password" }
    provider { "shopify" }
    website { "https://pembertonrank.com" }
  end
end
