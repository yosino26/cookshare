Rails.application.routes.draw do
  devise_for :users

  # トップページ
  root 'recipes#index'
  # レシピ
  resources :recipes do
    collection do
      get :search
      get :feed
    end
    resource  :favorite, only: [:create, :destroy]
    resources :comments, only: [:create, :destroy]
    resources :ratings,  only: [:create]
  end
  # ユーザー
  resources :users, only: [:show, :edit, :update] do
    member { get :favorites }
    resource :follow, only: [:create, :destroy]
  end
  # レポート（公開側）
  resources :reports, only: [:new, :create]
  get 'reports/recipes/:recipe_id/new',   to: 'reports#new', as: :new_recipe_report
  get 'reports/comments/:comment_id/new', to: 'reports#new', as: :new_comment_report
  get 'reports/users/:user_id/new',       to: 'reports#new', as: :new_user_report

  # 管理者
  namespace :admin do
    root 'dashboard#index'

    resources :reports, only: [:index, :show, :update] do
      member do
        patch :resolve
        patch :dismiss
        patch :investigate
      end
    end

    get 'users/export', to: 'users#export', as: :users_export
    resources :users, only: [:index, :show, :edit, :update] do
      member do
        patch :toggle_admin
        patch :suspend
        patch :unsuspend
        patch :promote
      end
    end

    get 'recipes/export', to: 'recipes#export', as: :recipes_export
    resources :recipes, only: [:index, :show, :edit, :update, :destroy] do
      member do
        patch :hide
        patch :unhide
      end
    end
    resources :comments, only: [:index, :show, :destroy] do
      collection { patch :bulk }   # => bulk_admin_comments_path
      member do
        patch :hide               # => hide_admin_comment_path(:id)
        patch :unhide             # => unhide_admin_comment_path(:id)
      end
    end
  end
  namespace :api do
    resources :recipes, only: [:index]
  end
end
