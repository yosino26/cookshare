class RecipesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index, :show]
  before_action :set_recipe, only: [:show, :edit, :update, :destroy]
  before_action :correct_user, only: [:edit, :update, :destroy]

  def index
    @recipes = Recipe.includes(:user, image_attachment: :blob)
    .recent
    .page(params[:page])
    .per(12)

    # 検索機能
    if params[:search].present?
      @recipes = @recipes.search_by_title_and_description(params[:search])
    end
    
    # 調理時間フィルター
    if params[:cooking_time].present?
      @recipes = @recipes.by_cooking_time(params[:cooking_time])
    end
    
   # ソート処理
   @recipes = case params[:sort]
              when 'popular'
                @recipes.popular
              when 'top_rated'
                @recipes.top_rated
              when 'cooking_time'
                @recipes.order(:cooking_time)
              else
                @recipes.recent
              end
  
   # ページネーション
   @recipes = @recipes.page(params[:page]).per(12)
   
   # 統計情報
   @total_recipes = Recipe.count
   @total_users = User.count
   @recent_recipes = Recipe.recent.limit(6)
  end

  def show
    # @recipeは before_action で設定済み
    @user   = @recipe.user   # ←@user が nil（→ avatar で落ちる）を防ぐ
  end

  def new
    @recipe = current_user.recipes.build
    @recipe.ingredients.build(order_number: 1) # ← 名前と分量を同じ行で入れる前提の空行
    @recipe.steps.build(step_number: 1)
  end

  def create
    @recipe = current_user.recipes.build(recipe_params)
    
    if @recipe.save
      redirect_to @recipe, notice: 'レシピが投稿されました！'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    # @recipeは before_action で設定済み
  end

  def update
    if @recipe.update(recipe_params)
      redirect_to @recipe, notice: 'レシピが更新されました！'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @recipe.destroy
    redirect_to recipes_path, notice: 'レシピが削除されました。'
  end

  def feed
    if user_signed_in?
      # フォローしているユーザーのレシピ + 自分のレシピ
      following_ids = current_user.followings.pluck(:id)
      following_ids << current_user.id
      
      @recipes = Recipe.includes(:user, :favorites, :ratings)
                       .where(user_id: following_ids)
                       .recent
                       .page(params[:page]).per(10)
    else
      redirect_to recipes_path, alert: 'ログインが必要です'
    end
  end

  private
  def set_recipe
    @recipe = Recipe.find(params[:id])
  end

  def recipe_params
    params.require(:recipe).permit(
      :title, :description, :cooking_time, :servings, :image,
      ingredients_attributes: [:id, :name, :amount, :order_number, :_destroy],
      steps_attributes:       [:id, :instruction, :step_number, :_destroy]
    )
  end

  def correct_user
    redirect_to recipes_path unless @recipe.user == current_user
  end
end
