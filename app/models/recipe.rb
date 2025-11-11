class Recipe < ApplicationRecord
  include Reportable

  belongs_to :user

  has_many :favorites, dependent: :destroy
  has_many :favorited_by, through: :favorites, source: :user

  has_one_attached :image

  has_many :ingredients, dependent: :destroy, inverse_of: :recipe
  has_many :steps,       dependent: :destroy,  inverse_of: :recipe
  has_many :comments, dependent: :destroy
  has_many :ratings,  dependent: :destroy

  has_many :recipe_categories, dependent: :destroy
  has_many :categories, through: :recipe_categories

  accepts_nested_attributes_for :ingredients,
    allow_destroy: true,
    reject_if: ->(attrs) { attrs['name'].blank? && attrs['amount'].blank? }

  accepts_nested_attributes_for :steps,
    allow_destroy: true,
    reject_if: ->(attrs) { attrs['instruction'].blank? }

  validates :title,       presence: true, length: { maximum: 30 }
  validates :description, presence: true, length: { maximum: 1000 }
  validates :cooking_time, presence: true,
            numericality: { greater_than: 0, less_than: 1000 }
  validates :servings, presence: true,
            numericality: { greater_than: 0, less_than_or_equal_to: 20 }

  # 並び順（タイブレーク付き）
  scope :recent, -> { order(created_at: :desc, id: :desc) }

  scope :popular, -> {
    left_joins(:favorites)
      .group(:id)
      .order(Arel.sql('COUNT(favorites.id) DESC'), id: :desc)
  }

  scope :top_rated, -> {
    left_joins(:ratings)
      .group(:id)
      .order(Arel.sql('COALESCE(AVG(ratings.score), 0) DESC'), id: :desc)
  }

  scope :by_cooking_time, ->(time) { where('cooking_time <= ?', time.to_i) }
  scope :visible,   -> { where(hidden: false) }
  scope :hidden,    -> { where(hidden: true)  }
  scope :published, -> { where(hidden: false) }

  scope :search_by_title_and_description, ->(keyword) {
    where("title ILIKE ? OR description ILIKE ?", "%#{keyword}%", "%#{keyword}%")
  }

  def ordered_ingredients = ingredients.order(:order_number)
  def ordered_steps       = steps.order(:step_number)

  def favorite_count
    association(:favorites).loaded? ? favorites.size : favorites.count
  end

  def comment_count
    association(:comments).loaded? ? comments.size : comments.count
  end

  def rating_count
    association(:ratings).loaded? ? ratings.size : ratings.count
  end

  def average_rating
    ratings.average(:score).to_f.round(1)
  end

  def rating_stars
    avg = average_rating
    full = avg.floor
    half = (avg - full) >= 0.5 ? 1 : 0
    empty = 5 - full - half
    "★" * full + "☆" * half + "☆" * empty
  end

  def category_names = categories.pluck(:name)

  def safe_to_display?      = pending_reports_count == 0
  def requires_moderation?  = pending_reports_count > 0
end