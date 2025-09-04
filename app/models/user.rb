class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

         
  # バリデーション追加
  validates :name, presence: true, length: { maximum: 20 }
  validates :bio, length: { maximum: 500 }

  # 関連
  has_many :recipes, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_one_attached :avatar

  # ユーザーの投稿数を取得するメソッド
  def recipe_count
      recipes.count
  end

  def display_name
    name.presence || "匿名ユーザー"
  end
  
  # お気に入り関連のリレーション追加
  has_many :favorites, dependent: :destroy
  has_many :favorite_recipes, through: :favorites, source: :recipe
  
  # お気に入りかどうかを判定するメソッド
  def favorited?(recipe)
    favorites.exists?(recipe: recipe)
  end
  
  # お気に入りに追加
  def favorite(recipe)
    favorites.find_or_create_by(recipe: recipe)
  end
  
  # お気に入りから削除
  def unfavorite(recipe)
    favorites.find_by(recipe: recipe)&.destroy
  end

end
