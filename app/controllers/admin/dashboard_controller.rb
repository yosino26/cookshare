class Admin::DashboardController < Admin::BaseController
  def index
    @stats = gather_dashboard_stats
    @recent_activities = gather_recent_activities
    @pending_reports = gather_pending_reports
  end

  private

  # ダッシュボード統計情報を収集(管理者ダッシュボードに表示する統計情報をまとめて返すメソッド)
  def gather_dashboard_stats
    {
      # 基本統計
      total_users: User.count,
      total_recipes: Recipe.count,
      total_comments: Comment.count,
      total_reports: Report.count,
      
      # 今日の統計
      today_users: User.where('created_at >= ?', Date.current).count,
      today_recipes: Recipe.where('created_at >= ?', Date.current).count,
      today_comments: Comment.where('created_at >= ?', Date.current).count,
      today_reports: Report.where('created_at >= ?', Date.current).count,
      
      # 今週の統計  
      week_users: User.where('created_at >= ?', 1.week.ago).count,
      week_recipes: Recipe.where('created_at >= ?', 1.week.ago).count,
      week_comments: Comment.where('created_at >= ?', 1.week.ago).count,
      week_reports: Report.where('created_at >= ?', 1.week.ago).count,
      
      # レポート統計
      pending_reports: Report.pending.count,
      investigating_reports: Report.investigating.count,
      resolved_reports: Report.resolved.count,
      dismissed_reports: Report.dismissed.count
    }
  end

  # 最近のアクティビティを収集
  def gather_recent_activities
    {
      recent_users: User.order(created_at: :desc).limit(5).includes(:avatar_attachment),
      recent_recipes: Recipe.order(created_at: :desc).limit(5).includes(:user, :image_attachment),
      recent_comments: Comment.order(created_at: :desc).limit(5).includes(:user, :recipe),
      recent_reports: Report.order(created_at: :desc).limit(5).includes(:reporter, :reportable)
    }
  end

  # 未対応レポートを収集
  def gather_pending_reports
    Report.pending
          .includes(:reporter, :reportable)
          .order(created_at: :desc)
          .limit(10)
  end
end