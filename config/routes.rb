Rails.application.routes.draw do
  devise_for :users

  # トップページ
  root 'recipes#index'

  # レシピ
  resources :recipes do
    collection do
      get :search   # /recipes/search
    end
    resource :favorite, only: [:create, :destroy]  # /recipes/:recipe_id/favorite
    resources :comments, only: [:create, :destroy]  # 追加
    resources :ratings, only: [:create]  # 追加
  end

  # ユーザー（プロフィール表示・編集・更新・お気に入り一覧）
  resources :users, only: [:show, :edit, :update] do
    member do
      get :favorites  # /users/:id/favorites
    end
    resource :follow, only: [:create, :destroy] 
  end
end