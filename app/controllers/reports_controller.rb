class ReportsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_reportable, only: [:new, :create]

  def new
    # 既に通報済みならフォームは出さずに戻す
    if @reportable.reported_by?(current_user)
      flash[:info] = 'この項目は既にレポート済みです'
      return redirect_back(fallback_location: @reportable)
    end

    # 自分自身/自分の投稿は通報不可（任意）
    if reporting_own_resource?
      flash[:alert] = '自身や自分の投稿はレポートできません'
      return redirect_back(fallback_location: @reportable)
    end
    @report = Report.new
    respond_to do |format|
      format.html
      format.js   # Ajax対応を続けるなら残す
    end
  end
  def create
    # × current_user.reports.find_or_initialize_by(...)
    @report = current_user.submitted_reports.find_or_initialize_by(reportable: @reportable)
    @report.assign_attributes(report_params)
  
    if @report.persisted?
      flash[:alert] = 'この項目は既にレポート済みです'
      return redirect_back(fallback_location: @reportable)
    end
  
    if @report.save
      flash[:success] = 'レポートを送信しました。内容を確認後、対応いたします。'
      redirect_back(fallback_location: @reportable)
    else
      render :new, status: :unprocessable_content  # Rack 3 対応
    end
  rescue ActiveRecord::RecordNotUnique
    flash[:info] = 'この項目は既にレポート済みです'
    redirect_back(fallback_location: @reportable)
  end

  private

  def set_reportable
    @reportable = find_reportable
    unless @reportable
      flash[:alert] = 'レポート対象が見つかりません'
      redirect_to root_path
    end
  end

  def find_reportable
    # ① 汎用パラメータ（reports_path?reportable_type=Recipe&reportable_id=1）
    if params[:reportable_type].present? && params[:reportable_id].present?
      klass = params[:reportable_type].to_s.safe_constantize
      return klass&.find_by(id: params[:reportable_id]) if klass
    end

    # ② 既存の個別ショートカット
    return Recipe.find_by(id: params[:recipe_id])   if params[:recipe_id]
    return Comment.find_by(id: params[:comment_id]) if params[:comment_id]
    return User.find_by(id: params[:user_id])       if params[:user_id]

    nil
  end

  # 自分自身/自分の投稿を通報しようとしてないか（任意ガード）
  def reporting_own_resource?
    case @reportable
    when User
      @reportable.id == current_user.id
    when Recipe, Comment
      @reportable.respond_to?(:user_id) && @reportable.user_id == current_user.id
    else
      false
    end
  end

  def report_params
    params.require(:report).permit(:reason, :description)
  end
end
