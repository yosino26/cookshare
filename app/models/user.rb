class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

         
  # バリデーション追加
  validates :name, presence: true, length: { maximum: 20 }

  # リレーション追加
  has_many :recipes, dependent: :destroy

  # ユーザーの投稿数を取得するメソッド
  def recipe_count
      recipes.count
  end

  
  # 後で追加予定のリレーション# has_many :recipes, dependent: :destroy
end
