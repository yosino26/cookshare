class Recipe < ApplicationRecord
  # リレーション
  belongs_to :user

  # 画像アップロード（Active Storage）
  has_one_attached :image

  # 新しく追加するリレーション
  has_many :ingredients, dependent: :destroy
  has_many :steps, dependent: :destroy

  # ネストされた属性を許可（フォームで使用）
  accepts_nested_attributes_for :ingredients, 
  allow_destroy: true, 
  reject_if: :all_blank
    accepts_nested_attributes_for :steps, 
  allow_destroy: true, 
  reject_if: :all_blank
  
  # バリデーション
  validates :title, presence: true, length: { maximum: 30 }
  validates :description, presence: true, length: { maximum: 1000 }
  validates :cooking_time, presence: true, 
                           numericality: { greater_than: 0, less_than: 1000 }
  validates :servings, presence: true, 
                       numericality: { greater_than: 0, less_than: 20 }
  
  # スコープ（よく使う検索条件）
  scope :recent, -> { order(created_at: :desc) }
  scope :by_cooking_time, ->(time) { where('cooking_time <= ?', time) }

    # 新しく追加するメソッド
    def ordered_ingredients
      ingredients.ordered
    end
    
    def ordered_steps
      steps.ordered
    end
end
