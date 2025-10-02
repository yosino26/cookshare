module Reportable
  extend ActiveSupport::Concern
  
  # このモジュールがincludeされたときに実行される
  included do
    # ポリモーフィック関連でレポートと紐づく
    has_many :reports, as: :reportable, dependent: :destroy
  end
  
  # このモデルが特定のユーザーによってレポートされているかチェック
  def reported_by?(user)
    reports.where(reporter: user).exists?
  end
  
  # このモデルに対するレポート数を取得
  def report_count
    reports.count
  end
  
  # 最新のレポートを取得
  def latest_report
    reports.order(created_at: :desc).first
  end
  
  # 未解決のレポート数を取得
  def pending_reports_count
    reports.pending.count
  end

end