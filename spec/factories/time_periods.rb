FactoryBot.define do
  factory :time_period, class: PR::Common::Models::TimePeriod do
    trait :installed do
      kind { :installed }
    end

    trait :reinstalled do
      kind { :reinstalled }
    end

    trait :reopened do
      kind { :reopened }
    end

    trait :uninstalled do
      kind { :uninstalled }
    end

    trait :closed do
      kind { :closed }
    end
  end
end
