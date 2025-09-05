class Comment < ApplicationRecord
  belongs_to :user
  belongs_to :recipe

  validates :content, presence: true, length: { maximum: 500 }
  
  # 新しい順で取得
  scope :recent, -> { order(created_at: :desc) }
end
