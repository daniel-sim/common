FactoryBot.define do
  factory :shop do
    sequence(:shopify_domain) { |n| "shop#{n}" }
    shopify_token { "MyString" }
    shopify_plan { "affiliate" }
    uninstalled { false }

    trait :uninstalled do
      uninstalled { true }
    end

    trait :cancelled do
      shopify_plan { "cancelled" }
    end

    trait :frozen do
      shopify_plan { "frozen" }
    end

    trait :with_user do
      user
    end
  end
end
