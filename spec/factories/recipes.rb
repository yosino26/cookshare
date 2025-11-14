FactoryBot.define do
  factory :recipe do
    association :user
    title         { "テストレシピ" }
    description   { "テスト用の説明文です。" }
    cooking_time  { 10 }
    servings      { 2 }
    hidden        { false }  # 既定＝公開

    trait :published do
      hidden { false }
    end

    trait :hidden do
      hidden { true }
    end
  end
end