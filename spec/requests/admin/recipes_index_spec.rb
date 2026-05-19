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

        it "タイトルまたは説明文に一致したレシピだけ表示される" do
          get admin_recipes_path, params: { search: "カレー" }

          expect(response).to have_http_status(:ok)
          expect(response.body).to include("和風カレー")
          expect(response.body).to include("別の料理")
          expect(response.body).not_to include("オムライス")
        end
      end

      describe "並び順" do
        let!(:old_recipe) do
          create(
            :recipe,
            title: "古いレシピ",
            created_at: 3.days.ago,
            cooking_time: 30,
            user: user
          )
        end

        let!(:middle_recipe) do
          create(
            :recipe,
            title: "中間のレシピ",
            created_at: 2.days.ago,
            cooking_time: 20,
            user: user
          )
        end

        let!(:new_recipe) do
          create(
            :recipe,
            title: "新しいレシピ",
            created_at: 1.day.ago,
            cooking_time: 10,
            user: user
          )
        end
        it "created_descでは新しい順に表示される" do
          get admin_recipes_path, params: { sort: "created_desc" }

          expect(response).to have_http_status(:ok)

          expect(response.body.index("新しいレシピ")).to be < response.body.index("中間のレシピ")
          expect(response.body.index("中間のレシピ")).to be < response.body.index("古いレシピ")
        end
        it "created_ascでは古い順に表示される" do
          get admin_recipes_path, params: { sort: "created_asc" }

          expect(response).to have_http_status(:ok)

          expect(response.body.index("古いレシピ")).to be < response.body.index("中間のレシピ")
          expect(response.body.index("中間のレシピ")).to be < response.body.index("新しいレシピ")
        end
        it "cooking_timeでは調理時間が短い順に表示される" do
          get admin_recipes_path, params: { sort: "cooking_time" }

          expect(response).to have_http_status(:ok)

          expect(response.body.index("新しいレシピ")).to be < response.body.index("中間のレシピ")
          expect(response.body.index("中間のレシピ")).to be < response.body.index("古いレシピ")
        end
      end
      describe "人気順" do
        let!(:popular_recipe) do
          create(
            :recipe,
            title: "人気レシピ",
            created_at: 3.days.ago,
            user: user
          )
        end

        let!(:normal_recipe) do
          create(
            :recipe,
            title: "普通のレシピ",
            created_at: 2.days.ago,
            user: user
          )
        end

        let!(:low_recipe) do
          create(
            :recipe,
            title: "少ないレシピ",
            created_at: 1.day.ago,
            user: user
          )
        end

        before do
          3.times do
            create(:favorite, recipe: popular_recipe, user: create(:user))
          end

          create(:favorite, recipe: normal_recipe, user: create(:user))
        end

end