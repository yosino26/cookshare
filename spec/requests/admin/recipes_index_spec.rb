require "rails_helper"

RSpec.describe "Admin::Recipes 一覧系", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:user)  { create(:user) }

  describe "GET /admin/recipes" do
    context "未ログイン" do
      it "ログイン画面へリダイレクトされる" do
        get admin_recipes_path

        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
    context "一般ユーザー" do
      before do
        sign_in user
      end

      it "rootへリダイレクトされる" do
        get admin_recipes_path

        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(root_path)
      end
    end

    context "管理者" do
      before do
        sign_in admin
      end

      it "200 OKでレシピ一覧を表示できる" do
        get admin_recipes_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("レシピ一覧")
      end

      describe "検索" do
        let!(:matched_by_title) do
          create(
            :recipe,
            title: "和風カレー",
            description: "普通の説明文です。",
            user: user
          )
        end

        let!(:matched_by_description) do
          create(
            :recipe,
            title: "別の料理",
            description: "カレー粉を使ったレシピです。",
            user: user
          )
        end

        let!(:not_matched) do
          create(
            :recipe,
            title: "オムライス",
            description: "卵を使ったレシピです。",
            user: user
          )
        end
end