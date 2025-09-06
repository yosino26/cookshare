class RatingsController < ApplicationController
  before_action :set_recipe

  def create
    @rating = @recipe.ratings.find_or_initialize_by(user: current_user)
    @rating.score = params[:score].to_i
    
    if @rating.save
      redirect_to @recipe, notice: '評価を投稿しました'
    else
      redirect_to @recipe, alert: '評価の投稿に失敗しました'
    end
  end

  private

  def set_recipe
    @recipe = Recipe.find(params[:recipe_id])
  end
end
