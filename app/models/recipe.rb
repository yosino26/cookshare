class Recipe < ApplicationRecord
  # リレーション
  belongs_to :user

  # お気に入り関連のリレーション追加
  has_many :favorites, dependent: :destroy
  #中間テーブルを経由して関連付け
  has_many :favorited_by, through: :favorites, source: :user   

  # 画像アップロード（Active Storage）
  has_one_attached :image

  # 関連
  has_many :ingredients, dependent: :destroy, inverse_of: :recipe
  has_many :steps,       dependent: :destroy,  inverse_of: :recipe
  has_many :comments, dependent: :destroy

  # ネスト属性
  accepts_nested_attributes_for :ingredients,
    allow_destroy: true,
    reject_if: ->(attrs) { attrs['name'].blank? && attrs['amount'].blank? }

  accepts_nested_attributes_for :steps,
    allow_destroy: true,
    reject_if: ->(attrs) { attrs['instruction'].blank? }

  # バリデーション
  validates :title,       presence: true, length: { maximum: 30 }
  validates :description, presence: true, length: { maximum: 1000 }
  validates :cooking_time,
    presence: true,
    numericality: { greater_than: 0, less_than: 1000 }
  validates :servings,
    presence: true,
    numericality: { greater_than: 0, less_than_or_equal_to: 20 }

  # スコープ
  scope :recent, -> { order(created_at: :desc) }
  scope :by_cooking_time, ->(time) { where('cooking_time <= ?', time.to_i) }

  # 検索用スコープ
  scope :search_by_title_and_description, ->(keyword) {
      where("title ILIKE ? OR description ILIKE ?", "%#{keyword}%", "%#{keyword}%")
  }

  
  # 表示用の並び
  def ordered_ingredients
    ingredients.order(:order_number)
  end

  def ordered_steps
    steps.order(:step_number)
  end

  # （任意）Active Storageの型/サイズチェック
  # validate :image_type_and_size
  # def image_type_and_size
  #   return unless image.attached?
  #   unless image.content_type.in?(%w[image/png image/jpeg image/webp])
  #     errors.add(:image, 'はPNG/JPEG/WEBPのみアップロードできます')
  #   end
  #   if image.byte_size > 5.megabytes
  #     errors.add(:image, 'は5MB以下にしてください')
  #   end
  # end


  
  
  # お気に入り数を取得
  def favorite_count
    favorites.count
  end

  # コメント数を取得
  def comment_count
    comments.count
  end
  
  # 人気順のスコープ（お気に入り数順）
  scope :popular, -> { 
    left_joins(:favorites)
      .group(:id)
      .order('COUNT(favorites.id) DESC')
  }
end

