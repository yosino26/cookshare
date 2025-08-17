class RecipesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index, :show]

  def index
    # 後でレシピデータを取得する処理を追加
    @recipes = []  # 現在は空配列
  end

  def show
    @recipe = Recipe.find(params[:id])
  end
end
