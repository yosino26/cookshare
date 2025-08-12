Rails.application.routes.draw do
  root 'recipes#index'  # トップページをレシピ一覧に
  
  # 後でresourcesに変更予定
  get '/recipes', to: 'recipes#index'
end
