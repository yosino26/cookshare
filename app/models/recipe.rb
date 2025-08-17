class Recipe < ApplicationRecord
    # リレーション
    belongs_to :user

  # 画像アップロード（Active Storage）
  has_one_attached :image
  
  # バリデーション
  validates :title, presence: true, length: { maximum: 30 }
  validates :description, presence: true, length: { maximum: 1000 }
  validates :cooking_time, presence: true, 
                           numericality: { greater_than: 0, less_than: 1000 }
  validates :servings, presence: true, 
                       numericality: { greater_than: 0, less_than: 20 }
  
end
