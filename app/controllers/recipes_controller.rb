class RecipesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index, :show]
  before_action :set_recipe, only: [:show, :edit, :update, :destroy]
  before_action :correct_user, only: [:edit, :update, :destroy]

  def index
    @recipes = Recipe.includes(:user).recent.limit(12)
    # includes(:user) でN+1問題を防ぐ
  end

  def show
    # @recipeは before_action で設定済み
  end

  def new
    @recipe = current_user.recipes.build
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
  

  private
  def set_recipe
    @recipe = Recipe.find(params[:id])
  end

  def recipe_params
    params.require(:recipe).permit(:title, :description, :cooking_time, :servings, :image)
  end
  def recipe_params
    params.require(:recipe).permit(
      :title, :description, :cooking_time, :servings, :image,
      ingredients_attributes: [:id, :name, :amount, :order_number, :_destroy],
      steps_attributes: [:id, :instruction, :step_number, :_destroy]
    )
  end

  def correct_user
    redirect_to recipes_path unless @recipe.user == current_user
  end
end
