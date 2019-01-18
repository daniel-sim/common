FactoryBot.define do
  factory :shop do
    sequence(:shopify_domain) { |n| "shop#{n}" }
    shopify_token { "MyString" }
    plan_name { "affiliate" }
    uninstalled { false }

    trait :uninstalled do
      uninstalled { true }
    end

    trait :cancelled do
      plan_name { "cancelled" }
    end

    trait :frozen do
      plan_name { "frozen" }
    end

    trait :with_user do
      user
    end
  end
end
