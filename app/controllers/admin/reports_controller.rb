# 
class Admin::ReportsController < Admin::BaseController
  before_action :set_report, only: [:show, :resolve, :dismiss, :investigate]
  before_action :set_admin_breadcrumbs

  def index
    @reports = build_reports_query
    @filter_params = filter_params
    @stats = report_stats
  end

  def show
    @report = Report.includes(:reporter, :reportable, :admin_user).find(params[:id])
    add_breadcrumb("レポート詳細", admin_report_path(@report))
  end

  def resolve
    if @report.resolve!(current_user, params[:admin_response])
      log_admin_action("resolved report", @report)
      flash[:success] = 'レポートを解決済みにしました'
    else
      flash[:alert] = 'レポートの更新に失敗しました'
    end
    redirect_to admin_report_path(@report)
  end

  def dismiss
    if @report.dismiss!(current_user, params[:admin_response])
      log_admin_action("dismissed report", @report)
      flash[:success] = 'レポートを却下しました'
    else
      flash[:alert] = 'レポートの更新に失敗しました'
    end
    redirect_to admin_report_path(@report)
  end

  def investigate
    if @report.update(status: 'investigating', admin_user: current_user)
      log_admin_action("started investigating report", @report)
      flash[:info] = 'レポートの調査を開始しました'
    else
      flash[:alert] = 'ステータスの更新に失敗しました'
    end
    redirect_to admin_report_path(@report)
  end

  private

  def set_report
    @report = Report.find(params[:id])
  end

  def build_reports_query
    reports = Report.includes(:reporter, :reportable, :admin_user)
    
    # ステータスでフィルタリング
    reports = reports.where(status: params[:status]) if params[:status].present?
    
    # 報告対象のタイプでフィルタリング
    reports = reports.where(reportable_type: params[:reportable_type]) if params[:reportable_type].present?
    
    # 期間でフィルタリング
    if params[:date_from].present?
      reports = reports.where('created_at >= ?', Date.parse(params[:date_from]))
    end
    
    if params[:date_to].present?
      reports = reports.where('created_at <= ?', Date.parse(params[:date_to]).end_of_day)
    end
    
    # ソート
    sort_column = params[:sort].presence || 'created_at'
    sort_direction = params[:direction].presence || 'desc'
    
    reports = reports.order("#{sort_column} #{sort_direction}")
    
    # ページネーション
    reports.page(params[:page]).per(20)
  end

  def filter_params
    {
      status: params[:status],
      reportable_type: params[:reportable_type],
      date_from: params[:date_from],
      date_to: params[:date_to],
      sort: params[:sort],
      direction: params[:direction]
    }
  end

  def report_stats
    {
      total: Report.count,
      pending: Report.pending.count,
      investigating: Report.investigating.count,
      resolved: Report.resolved.count,
      dismissed: Report.dismissed.count,
      today: Report.where('created_at >= ?', Date.current).count
    }
  end

  def add_breadcrumb(name, path)
    @breadcrumbs << { name: name, path: path }
  end
end