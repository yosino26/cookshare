FactoryBot.define do
  factory :comment do
    association :user
    association :recipe
    content { "コメント本文" }
  end
end
