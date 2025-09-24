# app/controllers/admin/comments_controller.rb
class Admin::CommentsController < Admin::BaseController
  before_action :set_admin_breadcrumbs

  def index
    # ✅ フィルタ用パラメータ（デフォルト付き）
    @filter_params = {
      search:    params[:search].to_s,
      status:    (params[:status].presence || ''),          # ''=全て（ビューと一致）
      sort:      (params[:sort].presence || 'created_desc'),
      per_page:  (params[:per_page].presence || '20'),      # ビューの選択肢に合わせて20
      recipe_id: params[:recipe_id].to_s,
      user_id:   params[:user_id].to_s,
      period:    params[:period].to_s                       # '', today, week, month
    }

    scope = Comment.includes(:user, :recipe)

    # （任意）検索
    if @filter_params[:search].present?
      scope = scope.where('comments.content ILIKE ?', "%#{@filter_params[:search]}%")
    end

    # （任意）ステータス絞り込み：enum(:status) or boolean(:hidden) どちらでも動くように
    case @filter_params[:status]
    when 'visible'
      if Comment.column_names.include?('status')
        scope = scope.where(status: 'visible')
      elsif Comment.column_names.include?('hidden')
        scope = scope.where(hidden: false)
      end
    when 'hidden'
      if Comment.column_names.include?('status')
        scope = scope.where(status: 'hidden')
      elsif Comment.column_names.include?('hidden')
        scope = scope.where(hidden: true)
      end
    end

    # 並び順（ビューの選択肢に対応）
    scope =
    case @filter_params[:sort]
    when 'created_asc' then scope.order(created_at: :asc)
    when 'recipe'      then scope.order(:recipe_id, created_at: :desc)
    when 'user'        then scope.order(:user_id,   created_at: :desc)
    else                    scope.order(created_at: :desc) # created_desc
    end

    # 統計（全体）
    @stats = {
      total:     Comment.count,
      today:     Comment.where(created_at: Time.zone.today.all_day).count,
      this_week: Comment.where(created_at: Time.zone.now.beginning_of_week..Time.zone.now).count
    }

    @comments = scope.page(params[:page]).per(@filter_params[:per_page].to_i)
  end

  def hide
    Comment.find(params[:id]).update!(hidden: true)
    redirect_back fallback_location: admin_comments_path, notice: '非表示にしました'
  end

  def unhide
    Comment.find(params[:id]).update!(hidden: false)
    redirect_back fallback_location: admin_comments_path, notice: '表示にしました'
  end

  def destroy
    comment = Comment.find(params[:id])
    comment.destroy
    redirect_back fallback_location: admin_comments_path, notice: 'コメントを削除しました'
  end
end