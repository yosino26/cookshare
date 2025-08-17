Rails.application.routes.draw do
  devise_for :users
  root 'recipes#index'  # トップページをレシピ一覧に
  
  # 後でresourcesに変更予定
  resources :recipes, only: [:index, :show]
end
