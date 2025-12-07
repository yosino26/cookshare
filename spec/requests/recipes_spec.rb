require 'rails_helper'

RSpec.describe "Recipes", type: :request do
  let(:user)       { create(:user) }
  let(:other_user) { create(:user) }
  let(:recipe)     { create(:recipe, user: user) }

  describe "GET /recipes" do
    it "一覧ページが表示されること" do
      get recipes_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /recipes" do
    let(:valid_params) do
      {
        recipe: {
          title:        "テストレシピ",
          description:  "説明テキスト",
          cooking_time: 30,
          servings:     2
        }
      }
    end

    let(:invalid_params) do
      {
        recipe: {
          title:        "",                 # タイトルが必須なのでNG
          description:  "説明テキスト",
          cooking_time: 30,
          servings:     2
        }
      }
    end

    context "ログイン済みで有効な値のとき" do
      it "レシピを1件作成し、詳細ページにリダイレクトされること" do
        sign_in user

        expect {
          post recipes_path, params: valid_params
        }.to change { Recipe.count }.by(1)

        created = Recipe.last
        expect(created.user).to eq user

        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(recipe_path(created))
        expect(flash[:notice]).to eq 'レシピが投稿されました！'
      end
    end

    context "ログイン済みだが無効な値のとき" do
      it "レシピは作成されず、newテンプレートが422で再表示されること" do
        sign_in user

        expect {
          post recipes_path, params: invalid_params
        }.not_to change { Recipe.count }

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "未ログインのとき" do
      it "レシピは作成されず、ログイン画面へリダイレクトされること" do
        expect {
          post recipes_path, params: valid_params
        }.not_to change { Recipe.count }

        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "PATCH /recipes/:id" do
    let(:update_params) do
      {
        recipe: {
          title:        "更新後タイトル",
          description:  recipe.description,
          cooking_time: recipe.cooking_time,
          servings:     recipe.servings
        }
      }
    end

    context "投稿者本人でログイン済みのとき" do
      it "レシピを更新し、詳細ページにリダイレクトされること" do
        sign_in user

        patch recipe_path(recipe), params: update_params
        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(recipe_path(recipe))
        expect(flash[:notice]).to eq 'レシピが更新されました！'

        expect(recipe.reload.title).to eq "更新後タイトル"
      end
    end

    context "投稿者以外のユーザーのとき" do
      it "レシピは更新されず、一覧にリダイレクトされること" do
        sign_in other_user

        patch recipe_path(recipe), params: update_params
        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(recipes_path)

        expect(recipe.reload.title).not_to eq "更新後タイトル"
      end
    end

    context "未ログインのとき" do
      it "レシピは更新されず、ログイン画面へリダイレクトされること" do
        patch recipe_path(recipe), params: update_params
        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "DELETE /recipes/:id" do
    context "投稿者本人でログイン済みのとき" do
      it "レシピを削除し、一覧にリダイレクトされること" do
        sign_in user
        recipe # 事前に作成

        expect {
          delete recipe_path(recipe)
        }.to change { Recipe.count }.by(-1)

        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(recipes_path)
        expect(flash[:notice]).to eq 'レシピが削除されました。'
      end
    end

    context "投稿者以外のユーザーのとき" do
      it "レシピは削除されず、一覧にリダイレクトされること" do
        sign_in other_user
        recipe # 事前に作成

        expect {
          delete recipe_path(recipe)
        }.not_to change { Recipe.count }

        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(recipes_path)
      end
    end

    context "未ログインのとき" do
      it "レシピは削除されず、ログイン画面へリダイレクトされること" do
        recipe

        expect {
          delete recipe_path(recipe)
        }.not_to change { Recipe.count }

        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "GET /recipes/feed" do
    context "ログイン済みのとき" do
      it "200でフィードが表示されること" do
        sign_in user
        get feed_recipes_path
        expect(response).to have_http_status(:ok)
      end
    end

    context "未ログインのとき" do
      it "一覧にリダイレクトされ、alertが設定されること" do
        get feed_recipes_path
        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(recipes_path)
        expect(flash[:alert]).to eq 'ログインが必要です'
      end
    end
  end
end