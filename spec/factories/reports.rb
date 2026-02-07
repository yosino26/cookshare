FactoryBot.define do
  factory :report do
    association :reporter,   factory: :user
    association :reportable, factory: :recipe   # ポリモーフィック先をレシピに

    reason { :spam }          # enum
    status { :pending }       # enum
    description { "不適切な内容があります。詳細を確認してください。" }

    trait :for_comment do
      association :reportable, factory: :comment
    end
  end
end