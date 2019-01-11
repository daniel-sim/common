FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password" }
    provider { "shopify" }
    website { "http://example.com" }
    sequence(:username) { |n| "user#{n}@example.com" }
  end
end
