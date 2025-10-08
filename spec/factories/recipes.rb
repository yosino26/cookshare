FactoryBot.define do
  factory :recipe do
    association :user
    title { "テストレシピ" }
    description { "テスト用の説明文です。" }
    cooking_time { 10 }
    servings { 2 }
  end
end