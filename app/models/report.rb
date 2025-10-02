class Report < ApplicationRecord
    # ===== 関連付け =====
    belongs_to :reporter, class_name: 'User'
    belongs_to :reportable, polymorphic: true
    belongs_to :admin_user, class_name: "User", foreign_key: :admin_user_id, optional: true
    
    # ===== バリデーション =====
    validates :reason, presence: true   #（reasonはenum。長さチェックはdescriptionに）
    validates :description, presence: true, length: { minimum: 10, maximum: 1000 }

    # 同じユーザーが同じ対象に重複レポートすることを防ぐ
    validates :reporter_id, uniqueness: { 
      scope: [:reportable_type, :reportable_id],
      message: "既にこの項目をレポートしています"
    }
    
    # ===== Enum定義 =====
    enum status: { pending: 0, investigating: 1, resolved: 2, dismissed: 3 }
    enum reason: { spam: 0, inappropriate: 1, copyright: 2, other: 3 }
    
    # ===== スコープ =====
    scope :recent, -> { order(created_at: :desc) }
    scope :with_status, ->(s) { s.present? ? where(status: statuses[s]) : all }
    scope :by_reportable_type, ->(type) { type.present? ? where(reportable_type: type) : all }
    
    # ===== インスタンスメソッド =====
    
    # レポートを解決済みにする
    def resolve!(admin, response = nil)
      raise ArgumentError, "adminが必要です" if admin.blank?
      raise StateError, "pending/investigating以外からは解決にできません" unless pending? || investigating?
  
      update!(
        status: :resolved,
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
    
    # 対応済みか（解決 or 却下）
    def resolved_or_dismissed?
      resolved? || dismissed?
    end
    # 便利メソッド（UI制御で利用）
    def self.already_reported?(user, record)
      where(reporter: user, reportable: record).exists?
    end
end
