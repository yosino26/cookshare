class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

         
  # バリデーション追加
  validates :name, presence: true, length: { maximum: 20 }
  validates :bio, length: { maximum: 500 }

  # 関連
  has_many :recipes, dependent: :destroy
  has_one_attached :avatar

  # ユーザーの投稿数を取得するメソッド
  def recipe_count
      recipes.count
  end

  def display_name
    name.presence || "匿名ユーザー"
  end
  
  # 後で追加予定のリレーション# has_many :recipes, dependent: :destroy
end
