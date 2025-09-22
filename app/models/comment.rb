class Comment < ApplicationRecord
  include Reportable

  belongs_to :user
  belongs_to :recipe

  validates :content, presence: true, length: { maximum: 500 }
  
  # 新しい順で取得
  scope :recent, -> { order(created_at: :desc) }

  # レポート機能関連（追加）
  def safe_to_display?
    pending_reports_count == 0
  end
  
  def requires_moderation?
    pending_reports_count > 0
  end
  
  def truncated_content(limit = 100)
    content.length > limit ? "#{content[0, limit]}..." : content
  end
end
