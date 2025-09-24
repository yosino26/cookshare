class Admin::RecipesController < Admin::BaseController
  before_action :set_recipe, only: [:show, :destroy, :hide, :unhide] 

  def index
    # フィルタ（検索・並び順・件数）
    @filter_params = {
      search:   params[:search].to_s,
      sort:     (params[:sort].presence || 'created_desc').to_s,
      per_page: (params[:per_page].presence || '20').to_s
    }

    scope = Recipe
              .includes(:user, :favorites, :comments, image_attachment: :blob) # N+1回避
              .references(:user)

    # 検索
    if @filter_params[:search].present?
      if Recipe.respond_to?(:search_by_title_and_description)
        scope = scope.search_by_title_and_description(@filter_params[:search])
      else
        q = "%#{@filter_params[:search]}%"
        scope =
          begin
            scope.where('recipes.title ILIKE :q OR recipes.description ILIKE :q', q: q)
          rescue
            scope.where('recipes.title LIKE :q OR recipes.description LIKE :q', q: q)
          end
      end
    end

    # 並び順（存在チェックつき）
    scope =
      case @filter_params[:sort]
      when 'created_asc'   then scope.order(created_at: :asc)
      when 'cooking_time'
        Recipe.column_names.include?('cooking_time') ? scope.order(:cooking_time) : scope.order(created_at: :desc)
      when 'popular'
        # counter_cache があればそれ、無ければ favorites の数で並び替え（少し重い）
        if Recipe.column_names.include?('favorites_count')
          scope.order(favorites_count: :desc)
        else
          scope.left_joins(:favorites).group('recipes.id').order(Arel.sql('COUNT(favorites.id) DESC'))
        end
      else
        scope.order(created_at: :desc) # created_desc
      end

    per = @filter_params[:per_page].to_i
    per = 20 unless [20, 50, 100].include?(per)
    @recipes = scope.page(params[:page]).per(per)

    @stats = build_stats
  end

  def show
   # いったん公開側の詳細にリダイレクト（管理用のshowを作るまでの暫定）
   redirect_to recipe_path(@recipe)
  end

  def destroy
    @recipe.destroy
     redirect_to admin_recipes_path, notice: 'レシピを削除しました'
  end

  # CSVエクスポート（ルートを追加している場合）
  def export
    filters = {
      search: params[:search].to_s,
      sort:   (params[:sort].presence || 'created_desc').to_s
    }
    scope = Recipe
              .includes(:user, :favorites, :comments)
              .references(:user)

    # 検索
    if filters[:search].present?
      if Recipe.respond_to?(:search_by_title_and_description)
        scope = scope.search_by_title_and_description(filters[:search])
      else
        q = "%#{filters[:search]}%"
        scope =
          begin
            scope.where('recipes.title ILIKE :q OR recipes.description ILIKE :q', q: q)
          rescue
            scope.where('recipes.title LIKE :q OR recipes.description LIKE :q', q: q)
          end
      end
    end

    # 並び順
    scope =
      case filters[:sort]
      when 'created_asc'   then scope.order(created_at: :asc)
      when 'cooking_time'  then Recipe.column_names.include?('cooking_time') ? scope.order(:cooking_time) : scope.order(created_at: :desc)
      when 'popular'
        if Recipe.column_names.include?('favorites_count')
          scope.order(favorites_count: :desc)
        else
          scope.left_joins(:favorites).group('recipes.id').order(Arel.sql('COUNT(favorites.id) DESC'))
        end
      else
        scope.order(created_at: :desc)
      end

    require 'csv'
    csv = CSV.generate(headers: true) do |c|
      c << %w[id title user_email created_at cooking_time favorites comments]
      scope.find_each do |r|
        favorites_count = if r.respond_to?(:favorites_count)
                            r.favorites_count
                          else
                            r.association(:favorites).loaded? ? r.favorites.size : r.favorites.count
                          end
        comments_count  = if r.respond_to?(:comments_count)
                            r.comments_count
                          else
                            r.association(:comments).loaded? ? r.comments.size : r.comments.count
                          end
        c << [r.id, r.title, r.user&.email, r.created_at, (r.respond_to?(:cooking_time) ? r.cooking_time : nil), favorites_count, comments_count]
      end
    end

    send_data csv,
              filename: "recipes_#{Time.zone.now.strftime('%Y%m%d_%H%M%S')}.csv",
              type: 'text/csv'
  end

  def hide
    unless Recipe.column_names.include?('hidden')
      redirect_back fallback_location: admin_recipes_path, alert: 'hidden カラムがありません' and return
    end
    @recipe.update!(hidden: true)
    redirect_back fallback_location: admin_recipes_path, notice: 'レシピを非公開にしました'
  end

  def unhide
    unless Recipe.column_names.include?('hidden')
      redirect_back fallback_location: admin_recipes_path, alert: 'hidden カラムがありません' and return
    end
    @recipe.update!(hidden: false)
    redirect_back fallback_location: admin_recipes_path, notice: 'レシピを公開にしました'
  end

  # 必要なら show/edit/update/destroy を追加

  private

  def set_recipe
    @recipe = Recipe.find(params[:id])
  end

  def build_stats
    stats = {
      total: Recipe.count,
      today: Recipe.where('created_at >= ?', Time.zone.today.beginning_of_day).count,
      week:  Recipe.where('created_at >= ?', Time.zone.today.beginning_of_week).count
    }
    stats[:with_image] = Recipe.reflect_on_association(:image_attachment) ? Recipe.joins(:image_attachment).distinct.count : 0
    stats[:with_comments] = Recipe.reflect_on_association(:comments) ? Recipe.joins(:comments).distinct.count : 0
    stats[:avg_cooking_time] = Recipe.column_names.include?('cooking_time') ? Recipe.average(:cooking_time).to_i : nil
    stats
  end
end
