class User < ApplicationRecord
  include Reportable  # has_many :reports, as: :reportable （= 通報“される”側）   

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :trackable # 例：既存に追加            

  # バリデーション追加
  validates :name, presence: true, length: { maximum: 20 }
  validates :bio, length: { maximum: 500 }

  # 関連
  has_many :recipes, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_one_attached :avatar
  # レポート機能の関連付け（追加）
            # 通報“する”側は別名にする（衝突回避）
  has_many :submitted_reports, class_name: "Report", foreign_key: :reporter_id, inverse_of: :reporter, dependent: :nullify
  has_many :admin_handled_reports, class_name: 'Report', foreign_key: 'admin_user_id', dependent: :nullify


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

  # 評価関連
  def rated?(recipe)
    ratings.exists?(recipe: recipe)
  end
  def rating_for(recipe)
    ratings.find_by(recipe: recipe)
  end
  has_many :ratings, dependent: :destroy
  has_many :rated_recipes, through: :ratings, source: :recipe

  # フォロー機能
  has_many :active_follows, class_name: 'Follow', foreign_key: 'follower_id', dependent: :destroy
  has_many :passive_follows, class_name: 'Follow', foreign_key: 'following_id', dependent: :destroy

  # フォローしているユーザー
  has_many :followings, through: :active_follows, source: :following
  # フォロワー（自分をフォローしているユーザー）
  has_many :followers, through: :passive_follows, source: :follower

  # フォロー関連のメソッド
  def follow(user)
    return false if user == self
    active_follows.find_or_create_by(following: user)
  end

  def unfollow(user)
    active_follows.find_by(following: user)&.destroy
  end

  def following?(user)
    followings.include?(user)
  end

  def follower_count
    followers.count
  end

  def following_count
     followings.count
  end

  # 管理者機能
  def admin?
    admin == true
  end
  # 管理者にする
  def make_admin!
    update!(admin: true)
  end
  # 管理者権限を剥奪
  def remove_admin!
    update!(admin: false)
  end
  # 統計情報（追加）
  def reports_handled_count
    admin_handled_reports.count
  end

  # アカウント停止の処理
  def active_for_authentication?
    super && !suspended?
  end
  def suspended?
    # 無期限（suspended:true） or 期限付き（suspended_until）どちらでもロック扱い
    (self[:suspended] == true) || (suspended_until.present? && Time.current < suspended_until)
  end
  def inactive_message
    suspended? ? :locked : super
  end

end
