class Favorite < ApplicationRecord
  belongs_to :user
  belongs_to :recipe, counter_cache: true

  # 同じユーザー・レシピの組み合わせは一意
  validates :user_id, uniqueness: { scope: :recipe_id }
end
