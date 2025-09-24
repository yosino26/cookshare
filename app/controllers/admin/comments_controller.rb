# app/controllers/admin/comments_controller.rb
class Admin::CommentsController < Admin::BaseController
  before_action :set_admin_breadcrumbs

  def index
    @filter_params = {
      search:    params[:search].to_s,
      status:    (params[:status].presence || ''),            # ''=全て
      sort:      (params[:sort].presence || 'created_desc'),
      per_page:  (%w[20 50 100].include?(params[:per_page]) ? params[:per_page] : '20'),
      recipe_id: params[:recipe_id].to_s,
      user_id:   params[:user_id].to_s,
      period:    params[:period].to_s                         # '', today, week, month
    }

    scope = Comment.includes(:user, :recipe, :reports)

    # 検索
    if @filter_params[:search].present?
      q = ActiveRecord::Base.sanitize_sql_like(@filter_params[:search])
      scope = scope.where('comments.content ILIKE ?', "%#{q}%")
    end

    # 絞り込み
    scope = scope.where(recipe_id: @filter_params[:recipe_id]) if @filter_params[:recipe_id].present?
    scope = scope.where(user_id:   @filter_params[:user_id])   if @filter_params[:user_id].present?

    case @filter_params[:period]
    when 'today' then scope = scope.where(created_at: Time.zone.today.all_day)
    when 'week'  then scope = scope.where(created_at: Time.zone.now.beginning_of_week..Time.zone.now)
    when 'month' then scope = scope.where(created_at: Time.zone.now.beginning_of_month..Time.zone.now)
    end

    case @filter_params[:status]
    when 'visible'
      scope = scope.where(hidden: false) if Comment.column_names.include?('hidden')
      scope = scope.where(status: 'visible') if Comment.column_names.include?('status')
    when 'hidden'
      scope = scope.where(hidden: true) if Comment.column_names.include?('hidden')
      scope = scope.where(status: 'hidden') if Comment.column_names.include?('status')
    end

    # 並び順
    scope =
      case @filter_params[:sort]
      when 'created_asc' then scope.order(created_at: :asc)
      when 'recipe'      then scope.order(:recipe_id, created_at: :desc)
      when 'user'        then scope.order(:user_id,   created_at: :desc)
      else                    scope.order(created_at: :desc)
      end

    # 統計（ビューのキーに合わせる）
    @stats = {
      total:    Comment.count,
      visible:  (Comment.column_names.include?('hidden') ? Comment.where(hidden: false).count : nil),
      hidden:   (Comment.column_names.include?('hidden') ? Comment.where(hidden: true).count  : nil),
      today:    Comment.where(created_at: Time.zone.today.all_day).count,
      week:     Comment.where(created_at: Time.zone.now.beginning_of_week..Time.zone.now).count,
      reported: (Comment.reflect_on_association(:reports) ?
                  (Report.respond_to?(:pending) ?
                    Comment.joins(:reports).merge(Report.pending).distinct.count :
                    Comment.joins(:reports).distinct.count)
                 : nil)
    }

    @comments = scope.page(params[:page]).per(@filter_params[:per_page].to_i)
  end

  def hide
    Comment.where(id: params[:id]).update_all(hidden: true,  updated_at: Time.current)
    redirect_back fallback_location: admin_comments_path, notice: '非表示にしました'
  end

  def unhide
    Comment.where(id: params[:id]).update_all(hidden: false, updated_at: Time.current)
    redirect_back fallback_location: admin_comments_path, notice: '表示にしました'
  end

  def destroy
    Comment.where(id: params[:id]).destroy_all
    redirect_back fallback_location: admin_comments_path, notice: 'コメントを削除しました'
  end

  def bulk
    ids = Array(params[:comment_ids]).map(&:to_i).uniq
    return redirect_back fallback_location: admin_comments_path, alert: '対象が選択されていません' if ids.empty?

    case params[:bulk_action]
    when 'hide'   then Comment.where(id: ids).update_all(hidden: true,  updated_at: Time.current);  msg = "#{ids.size}件を非表示にしました"
    when 'show'   then Comment.where(id: ids).update_all(hidden: false, updated_at: Time.current);  msg = "#{ids.size}件を表示にしました"
    when 'delete' then Comment.where(id: ids).destroy_all;                                           msg = "#{ids.size}件を削除しました"
    else return redirect_back fallback_location: admin_comments_path, alert: 'アクションを選択してください'
    end

    redirect_back fallback_location: admin_comments_path, notice: msg
  end
end
