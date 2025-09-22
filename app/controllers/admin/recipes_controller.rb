class Admin::RecipesController < ApplicationController
  def index
    # フィルタ（必要最低限：検索・並び順・件数）
    @filter_params = {
      search:   params[:search].to_s,
      sort:     (params[:sort].presence || 'created_desc').to_s,
      per_page: (params[:per_page].presence || '20').to_s
    }

    scope = Recipe.includes(:user)

    # 検索（公開側のスコープがあれば優先）
    if @filter_params[:search].present?
      if scope.respond_to?(:search_by_title_and_description)
        scope = scope.search_by_title_and_description(@filter_params[:search])
      else
        q = "%#{@filter_params[:search]}%"
        begin
          scope = scope.where('title ILIKE :q OR description ILIKE :q', q: q)
        rescue
          scope = scope.where('title LIKE :q OR description LIKE :q', q: q) # MySQL 等
        end
      end
    end

    # 並び順（存在チェックつきで安全に）
    scope =
      case @filter_params[:sort]
      when 'created_asc'   then scope.order(created_at: :asc)
      when 'cooking_time'
        Recipe.column_names.include?('cooking_time') ? scope.order(:cooking_time) : scope.order(created_at: :desc)
      when 'popular'
        Recipe.column_names.include?('favorites_count') ? scope.order(favorites_count: :desc) : scope.order(created_at: :desc)
      else                   scope.order(created_at: :desc) # created_desc
      end

    per = @filter_params[:per_page].to_i
    per = 20 unless [20, 50, 100].include?(per)
    @recipes = scope.page(params[:page]).per(per)

    # ← これが無いとビューで @stats[:...] で落ちる
    @stats = build_stats
  end

  private

  def build_stats
    stats = {
      total: Recipe.count,
      today: Recipe.where('created_at >= ?', Time.zone.today.beginning_of_day).count,
      week:  Recipe.where('created_at >= ?', Time.zone.today.beginning_of_week).count
    }

    # 画像付き件数（has_one_attached :image を想定、無ければ 0）
    if Recipe.reflect_on_association(:image_attachment)
      stats[:with_image] = Recipe.joins(:image_attachment).distinct.count
    else
      stats[:with_image] = 0
    end

    # コメント付き件数（関連が無ければ 0）
    if Recipe.reflect_on_association(:comments)
      stats[:with_comments] = Recipe.joins(:comments).distinct.count
    else
      stats[:with_comments] = 0
    end

    # 平均調理時間（カラムがあれば）
    if Recipe.column_names.include?('cooking_time')
      stats[:avg_cooking_time] = Recipe.average(:cooking_time).to_i
    end

    stats
  end
end
