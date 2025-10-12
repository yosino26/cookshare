FactoryBot.define do
  factory :rating do
    association :user
    association :recipe
    score { 5 }
  end
end
