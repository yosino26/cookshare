class Admin::RecipesController < ApplicationController
  def index
    @recipes = Recipe.includes(:user).order(created_at: :desc).page(params[:page]).per(20)
  end
end
