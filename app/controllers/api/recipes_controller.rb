module Api
  class RecipesController < ApplicationController
    skip_before_action :authenticate_user!

    def index
      scope = Recipe.published

      # カテゴリ絞り込み（任意）
      scope = scope.by_category(params[:category_id]) if params[:category_id].present?

      # 並び順は共通スコープ recent を使用
      recipes = scope.recent.page(params[:page]).per(12)

      # 必要最低限のキーだけ返す（テストしやすく、漏洩も防ぐ）
      render json: recipes.as_json(only: [:id, :title, :created_at])
    end
  end
end