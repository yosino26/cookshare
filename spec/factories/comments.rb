FactoryBot.define do
  factory :comment do
    association :user
    association :recipe
    content { "おいしそう！" }  # ← body → content に変更
  end
end