class Favorite < ApplicationRecord
  belongs_to :user
  belongs_to :recipe, counter_cache: true

  # 同じユーザー内で recipe_id は一意
  validates :recipe_id, uniqueness: { scope: :user_id }
end