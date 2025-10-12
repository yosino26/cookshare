FactoryBot.define do
  factory :recipe_category do
    association :recipe
    association :category
  end
end