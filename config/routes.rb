Rails.application.routes.draw do
  devise_for :users

  # トップページ
  root 'recipes#index'

  # レシピ
  resources :recipes do
    collection do
      get :search   # /recipes/search
      get :feed  # タイムライン追加
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

  # ===== レポート機能（新規追加） =====
  resources :reports, only: [:create]
  get 'reports/recipes/:recipe_id/new',   to: 'reports#new', as: :new_recipe_report
  get 'reports/comments/:comment_id/new', to: 'reports#new', as: :new_comment_report
  get 'reports/users/:user_id/new',       to: 'reports#new', as: :new_user_report

  # ===== 管理者機能（新規追加） =====
  namespace :admin do
    root 'dashboard#index'  # admin/ でダッシュボードにアクセス
    
    resources :reports, only: [:index, :show] do
      member do
        patch :resolve      # レポート解決
        patch :dismiss      # レポート却下
        patch :investigate  # 調査開始
      end
    end
    
    resources :users, only: [:index, :show, :edit, :update] do
      member do
        patch :toggle_admin  # 管理者権限の付与・剥奪
      end
    end  
  
    resources :recipes, only: [:index, :show, :edit, :update, :destroy]
    # ← 追加
    resources :comments, only: [:index, :destroy]
  end 
end