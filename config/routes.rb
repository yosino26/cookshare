Rails.application.routes.draw do
  devise_for :users
  get 'recipes/index'
  root 'recipes#index'  # トップページをレシピ一覧に
  
  # 後でresourcesに変更予定
  get '/recipes', to: 'recipes#index'
end
