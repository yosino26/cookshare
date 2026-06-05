require "rails_helper"
require "csv"

RSpec.describe "Admin::Recipes CSVエクスポート", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:user)  { create(:user, email: "user@example.com") }
  describe "GET /admin/recipes/export" do
    context "未ログイン" do
      it "ログイン画面へリダイレクトされる" do
        get admin_recipes_export_path(format: :csv)

        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
    context "一般ユーザー" do
      before do
        sign_in user
      end

      it "rootへリダイレクトされる" do
        get admin_recipes_export_path(format: :csv)

        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(root_path)
      end
    end

    context "管理者" do
      before do
        sign_in admin
      end

      it "CSVを取得できる" do
        get admin_recipes_export_path(format: :csv)

        expect(response).to have_http_status(:ok)
        expect(response.media_type).to eq("text/csv")
      end
      it "CSVにヘッダーが含まれる" do
        get admin_recipes_export_path(format: :csv)

        csv = CSV.parse(response.body, headers: true)

        expect(csv.headers).to eq(
          %w[id title user_email created_at cooking_time favorites comments]
        )
      end

      it "CSVにレシピ情報が含まれる" do
        recipe = create(
          :recipe,
          title: "CSV用レシピ",
          cooking_time: 15,
          user: user
        )

        get admin_recipes_export_path(format: :csv)

        csv = CSV.parse(response.body, headers: true)
        row = csv.find { |r| r["id"].to_i == recipe.id }

        expect(row["title"]).to eq("CSV用レシピ")
        expect(row["user_email"]).to eq("user@example.com")
        expect(row["cooking_time"]).to eq("15")
      end
      let!(:matched_by_description) do
        create(
          :recipe,
          title: "CSV別料理",
          description: "カレー粉を使ったレシピです。",
          user: user
        )
      end4

end