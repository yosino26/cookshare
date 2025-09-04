FactoryBot.define do
  factory :comment do
    content { "MyText" }
    user { nil }
    recipe { nil }
  end
end
