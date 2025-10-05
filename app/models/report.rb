class Report < ApplicationRecord
  # ===== Associations =====
  belongs_to :reporter,   class_name: 'User', inverse_of: :submitted_reports
  belongs_to :reportable, polymorphic: true
  belongs_to :admin_user, class_name: 'User', foreign_key: :admin_user_id, optional: true

  # ===== Validations =====
  validates :reason, presence: true
  validates :description, presence: true, length: { minimum: 10, maximum: 1000 }
  validates :reporter_id, uniqueness: {
    scope: [:reportable_type, :reportable_id],
    message: "既にこの項目をレポートしています"
  }

  # ===== Enums =====
  enum status: { pending: 0, investigating: 1, resolved: 2, dismissed: 3 }
  enum reason: { spam: 0, inappropriate: 1, copyright: 2, other: 3 }

  # ===== Scopes =====
  scope :recent, -> { order(created_at: :desc) }
  scope :with_status, ->(s) {
    s.present? && statuses.key?(s.to_s) ? where(status: statuses[s]) : all
  }
  scope :by_reportable_type, ->(type) { type.present? ? where(reportable_type: type) : all }

  # ===== Defaults =====
  after_initialize :set_default_status, if: :new_record?

  STATUS_COLOR = {
    'pending'       => 'warning',
    'investigating' => 'info',
    'resolved'      => 'success',
    'dismissed'     => 'secondary'
  }.freeze

  STATUS_JA = {
    'pending'       => '未対応',
    'investigating' => '調査中',
    'resolved'      => '対応済み',
    'dismissed'     => '却下'
  }.freeze

  # ===== State Transitions =====
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

  def dismiss!(admin, response = nil)
    raise ArgumentError, "adminが必要です" if admin.blank?
    raise StateError, "pending/investigating以外からは却下にできません" unless pending? || investigating?

    update!(
      status: :dismissed,  # ← シンボルで統一
      admin_user: admin,
      admin_response: response,
      resolved_at: Time.current
    )
  end

  # ===== Helpers =====
  def reportable_type_japanese
    case reportable_type
    when 'Recipe'  then 'レシピ'
    when 'Comment' then 'コメント'
    when 'User'    then 'ユーザー'
    else reportable_type
    end
  end

  def reportable_title
    case reportable_type
    when 'Recipe'  then reportable&.title
    when 'Comment' then reportable&.content.to_s.truncate(50)
    when 'User'    then reportable&.name
    else "不明"
    end
  end

  def resolved_or_dismissed?
    resolved? || dismissed?
  end

  def self.already_reported?(user, record)
    where(reporter: user, reportable: record).exists?
  end

  def status_color
    STATUS_COLOR[status] || 'secondary'
  end

  def status_japanese
    STATUS_JA[status] || '未設定'
  end

  def reportable_admin_path
    return nil unless reportable
    helpers = Rails.application.routes.url_helpers
    helpers.polymorphic_path([:admin, reportable])
  rescue NoMethodError, ArgumentError
    helpers.polymorphic_path(reportable) rescue nil
  end

  class StateError < StandardError; end

  private
  def set_default_status
    self.status ||= :pending
  end
end
