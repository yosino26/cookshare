class FavoritesController < ApplicationController
  def create
    current_user.favorite(@recipe)
    redirect_back(fallback_location: @recipe)
  end

  def destroy
    current_user.unfavorite(@recipe)
    redirect_back(fallback_location: @recipe)
  end

  
  private
  def set_recipe
    @recipe = Recipe.find(params[:recipe_id])
  end
end
