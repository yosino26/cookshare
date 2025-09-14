class Report < ApplicationRecord
    # ===== 関連付け =====
    belongs_to :reporter, class_name: 'User'
    belongs_to :reportable, polymorphic: true
    belongs_to :admin_user, class_name: 'User', optional: true
    
    # ===== バリデーション =====
    validates :reason, presence: true, length: { minimum: 10, maximum: 500 }
    validates :description, length: { maximum: 1000 }
    validates :status, inclusion: { in: %w[pending investigating resolved dismissed] }
    
    # 同じユーザーが同じ対象に重複レポートすることを防ぐ
    validates :reporter_id, uniqueness: { 
      scope: [:reportable_type, :reportable_id],
      message: "既にこの項目をレポートしています"
    }
    
    # ===== Enum定義 =====
    enum status: {
      pending: 'pending',           # 未対応
      investigating: 'investigating', # 調査中
      resolved: 'resolved',         # 解決済み
      dismissed: 'dismissed'        # 却下
    }
    
    # ===== スコープ =====
    scope :recent, -> { order(created_at: :desc) }
    scope :by_status, ->(status) { where(status: status) if status.present? }
    scope :by_reportable_type, ->(type) { where(reportable_type: type) if type.present? }
    
    # ===== インスタンスメソッド =====
    
    # レポートを解決済みにする
    def resolve!(admin, response = nil)
      update!(
        status: 'resolved',
        admin_user: admin,
        admin_response: response,
        resolved_at: Time.current
      )
    end
    
    # レポートを却下する
    def dismiss!(admin, response = nil)
      update!(
        status: 'dismissed',
        admin_user: admin,
        admin_response: response,
        resolved_at: Time.current
      )
    end
    
    # レポート対象の種類を日本語で取得
    def reportable_type_japanese
      case reportable_type
      when 'Recipe'
        'レシピ'
      when 'Comment' 
        'コメント'
      when 'User'
        'ユーザー'
      else
        reportable_type
      end
    end
    
    # レポート対象のタイトルを取得
    def reportable_title
      case reportable_type
      when 'Recipe'
        reportable.title
      when 'Comment'
        reportable.content.truncate(50)
      when 'User'
        reportable.name
      else
        "不明"
      end
    end
    
    # 対応済みかどうか
    def resolved?
      resolved? || dismissed?
    end
end
