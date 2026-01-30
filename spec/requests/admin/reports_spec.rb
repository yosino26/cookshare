require "rails_helper"

RSpec.describe "Admin::Reports", type: :request do
  describe "GET /admin/reports" do
    let(:admin) { create(:user, :admin) }
    let(:user)  { create(:user) }

    context "認可" do
      it "管理者は 200 OK" do
        sign_in admin
        get admin_reports_path
        expect(response).to have_http_status(:ok)
      end

      it "一般ユーザーは root にリダイレクトされる" do
        sign_in user
        get admin_reports_path

        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq "管理者権限が必要です"
      end

      it "未ログインはログイン画面へリダイレクトされる" do
        get admin_reports_path

        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "フィルター" do
      let!(:reporter)        { create(:user, email: "reporter@example.com") }
      let!(:other_reporter)  { create(:user, email: "other@example.com") }

      let!(:recipe)          { create(:recipe, user: create(:user), title: "寿司タワー") }
      let!(:comment)         { create(:comment, user: create(:user), recipe: recipe, content: "これはスパムっぽいコメントです") }

      let!(:pending_recipe_report) do
        create(:report,
          reporter: reporter,
          reportable: recipe,
          status: :pending,
          reason: :spam
        )
      end

      let!(:resolved_user_report) do
        create(:report,
          reporter: other_reporter,
          reportable: create(:user, name: "通報対象ユーザー"),
          status: :resolved,
          reason: :other
        )
      end

      before { sign_in admin }

      it "status 指定で絞り込める" do
        get admin_reports_path, params: { status: "pending" }
        expect(response).to have_http_status(:ok)

        body = response.body
        expect(body).to include("reporter@example.com")
        expect(body).to include("寿司タワー")

        expect(body).not_to include("other@example.com")
        expect(body).not_to include("通報対象ユーザー")
      end
      it "reportable_type 指定で絞り込める（Recipe）" do
        get admin_reports_path, params: { reportable_type: "Recipe" }
        expect(response).to have_http_status(:ok)

        body = response.body
        expect(body).to include("寿司タワー")
        expect(body).not_to include("通報対象ユーザー")
        expect(body).not_to include("これはスパムっぽいコメントです")
      end
      it "reportable_type 指定で絞り込める（User）" do
        get admin_reports_path, params: { reportable_type: "User" }
        expect(response).to have_http_status(:ok)

        body = response.body
        expect(body).to include("通報対象ユーザー")
        expect(body).not_to include("寿司タワー")
        expect(body).not_to include("これはスパムっぽいコメントです")
      end
      it "期間（date_from / date_to）で絞り込める" do
        get admin_reports_path, params: { date_from: "2026-01-11", date_to: "2026-01-13" }
        expect(response).to have_http_status(:ok)

        body = response.body
        expect(body).to include("other@example.com")
        expect(body).to include("通報対象ユーザー")

        expect(body).not_to include("寿司タワー")
        expect(body).not_to include("これはスパムっぽいコメントです")
      end
    end
  end
end