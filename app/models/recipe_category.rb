class RecipeCategory < ApplicationRecord
  belongs_to :recipe
  belongs_to :category
    # 同じレシピ（recipe_id）内で、同じカテゴリ（category_id）を重複登録させない
  validates :category_id, uniqueness: { scope: :recipe_id } # recipe×category 一意
end
