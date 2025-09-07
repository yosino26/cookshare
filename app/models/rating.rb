class Rating < ApplicationRecord
  belongs_to :user
  belongs_to :recipe

  validates :score, presence: true, inclusion: { in: 1..5 }
  validates :user_id, uniqueness: { scope: :recipe_id }
  
  # 星の表示用
  def stars
    "★" * score + "☆" * (5 - score)
  end
end
