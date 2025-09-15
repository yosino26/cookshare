class ReportsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_reportable, only: [:new, :create]

  def new
    @report = Report.new
    
    # 既にレポート済みかチェック
    if @reportable.reported_by?(current_user)
      flash[:info] = 'この項目は既にレポート済みです'
      redirect_back_or_to(@reportable)
      return
    end

    respond_to do |format|
      format.html
      format.js   # Ajax対応
    end
  end

  def create
    @report = Report.new(report_params)
    @report.reporter = current_user
    @report.reportable = @reportable

    # 重複チェック
    if @reportable.reported_by?(current_user)
      flash[:alert] = 'この項目は既にレポート済みです'
      redirect_back_or_to(@reportable)
      return
    end

    respond_to do |format|
      if @report.save
        format.html do
          flash[:success] = 'レポートを送信しました。内容を確認後、対応いたします。'
          redirect_back_or_to(@reportable)
        end
        format.js do
          flash.now[:success] = 'レポートを送信しました'
        end
      else
        format.html { render :new }
        format.js   { render :new }
      end
    end
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
    # ポリモーフィック関連の対象を特定
    if params[:recipe_id]
      Recipe.find_by(id: params[:recipe_id])
    elsif params[:comment_id]
      Comment.find_by(id: params[:comment_id])
    elsif params[:user_id]
      User.find_by(id: params[:user_id])
    else
      nil
    end
  end

  def report_params
    params.require(:report).permit(:reason, :description)
  end
end
