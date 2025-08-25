Rails.application.routes.draw do
  get 'users/show'
  get 'users/edit'
  get 'users/update'
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
  resources :users, only: [:show, :edit, :update]
end