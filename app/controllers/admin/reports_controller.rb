class Admin::ReportsController < Admin::BaseController
  before_action :set_report, only: [:resolve, :dismiss, :investigate, :update]
  before_action :set_admin_breadcrumbs

  def index
    @filter_params = filter_params
    @reports = build_reports_query
    preload_reportables(@reports)  # ← 型ごとの深い関連をプリロード
    @stats = report_stats
  end

  def show
    @report = Report.includes(:reporter, :reportable, :admin_user).find(params[:id])
  
    # 同一報告者の他レポート
    @reporter_reports =
      if @report.reporter_id.present?
        Report.where(reporter_id: @report.reporter_id)
              .where.not(id: @report.id)
              .order(created_at: :desc)
              .limit(10)
      else
        Report.none
      end
  
    # 同一対象への他レポート
    @related_reports =
      if @report.reportable_type.present? && @report.reportable_id.present?
        Report.where(reportable_type: @report.reportable_type, reportable_id: @report.reportable_id)
              .where.not(id: @report.id)
              .order(created_at: :desc)
              .limit(10)
      else
        Report.none
      end
  end

  def update
    if params.dig(:report, :admin_note).present?
      # 管理者ノート保存
      if @report.update(admin_note: params[:report][:admin_note], admin_user: current_user)
        flash[:success] = 'ノートを保存しました'
        return redirect_to admin_report_path(@report)
      end
    end

    case params.dig(:report, :status).to_s
    when 'investigating'
      ok = @report.update(status: :investigating, admin_user: current_user)
    when 'resolved'
      ok = @report.resolve!(current_user, params[:admin_response]) rescue false
    when 'dismissed'
      ok = @report.dismiss!(current_user, params[:admin_response])  rescue false
    when 'pending'
      ok = @report.update(status: :pending, admin_user: current_user, admin_response: nil, resolved_at: nil)
    else
      ok = false
      flash[:alert] = '不正なステータスです'
    end

    if ok
      flash[:success] ||= '更新しました'
    else
      flash[:alert] ||= '更新に失敗しました'
    end
    redirect_to admin_report_path(@report)
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
    if @report.update(status: :investigating, admin_user: current_user) # ← シンボルで統一
      log_admin_action("started investigating report", @report)
      flash[:info] = 'レポートの調査を開始しました'
    else
      flash[:alert] = 'ステータスの更新に失敗しました'
    end
    redirect_to admin_report_path(@report)
  end

  private
  def preload_reportables(reports)
    recipes  = []
    comments = []
  
    reports.each do |r|
      case r.reportable_type
      when "Recipe"  then recipes  << r.reportable
      when "Comment" then comments << r.reportable
      end
    end
  
    # Rails 7.1+ の正しい呼び方（配列が空でもOK）
    ActiveRecord::Associations::Preloader.new(
      records: recipes,
      associations: :user
    ).call
  
    ActiveRecord::Associations::Preloader.new(
      records: comments,
      associations: [:user, :recipe]
    ).call
  end

  def set_report
    @report = Report.find(params[:id])
  end

  def build_reports_query
    reports = Report.includes(:reporter, :reportable, :admin_user)  # 深い先はpreloadで

    reports = reports.where(status: params[:status]) if params[:status].present?
    reports = reports.where(reportable_type: params[:reportable_type]) if params[:reportable_type].present?

    if params[:date_from].present?
      reports = reports.where('created_at >= ?', Date.parse(params[:date_from]))
    end
    if params[:date_to].present?
      reports = reports.where('created_at <= ?', Date.parse(params[:date_to]).end_of_day)
    end

    sort_column   = params[:sort].presence || 'created_at'
    sort_direction = params[:direction].presence || 'desc'
    reports = reports.order("#{sort_column} #{sort_direction}")

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
    @breadcrumbs <<({ name: name, path: path })
  end
end
