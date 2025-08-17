FactoryBot.define do
  factory :recipe do
    title { "MyString" }
    description { "MyText" }
    cooking_time { 1 }
    servings { 1 }
    user { nil }
  end
end
