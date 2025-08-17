Rails.application.routes.draw do
  devise_for :users
  root 'recipes#index'  # トップページをレシピ一覧に
  
  # RESTfulなレシピルーティング
  resources :recipes do
    # 検索機能（/recipes/search）
    collection do
      get :search
    end
  end
  
  # ユーザーのプロフィールページ
  resources :users, only: [:show]
end