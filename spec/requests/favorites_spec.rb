require 'rails_helper'

RSpec.describe "Favorites", type: :request do
  let(:user)   { create(:user) }
  let(:recipe) { create(:recipe) }

  describe "POST /recipes/:recipe_id/favorite" do
    context "ログイン済みのとき" do
      before do
        sign_in user
      end

      it "レシピをお気に入り登録できること" do
        # まだお気に入りが無い前提で 1 件増える
        expect {
          post recipe_favorite_path(recipe)
        }.to change { Favorite.count }.by(1)

        # リダイレクト先は fallback の recipe_path(recipe)
        expect(response).to have_http_status(:found) # 302
        expect(response).to redirect_to(recipe_path(recipe))
      end
    end

    context "未ログインのとき" do
      it "ログイン画面へリダイレクトされること" do
        expect {
          post recipe_favorite_path(recipe)
        }.not_to change { Favorite.count }

        expect(response).to have_http_status(:found) # 302
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "DELETE /recipes/:recipe_id/favorite" do
    context "ログイン済みのとき" do
      before do
        sign_in user
        user.favorite(recipe)  # 事前にお気に入り状態にしておく
      end

      it "レシピのお気に入りを解除できること" do
        expect {
          delete recipe_favorite_path(recipe)
        }.to change { Favorite.count }.by(-1)

        expect(response).to have_http_status(:found) # 302
        expect(response).to redirect_to(recipe_path(recipe))
      end
    end

    context "未ログインのとき" do
      before do
        # ログインしないまま、お気に入りレコードだけ先に作る想定
        create(:favorite, user: user, recipe: recipe)
      end

      it "ログイン画面へリダイレクトされ、お気に入りは削除されないこと" do
        expect {
          delete recipe_favorite_path(recipe)
        }.not_to change { Favorite.count }

        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end