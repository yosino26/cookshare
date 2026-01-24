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
      let!(:reporter) { create(:user, email: "reporter@example.com") }
      let!(:other_reporter) { create(:user, email: "other@example.com") }

      let!(:recipe) { create(:recipe, user: create(:user), title: "寿司タワー") }
      let!(:other_recipe) { create(:recipe, user: create(:user), title: "カレー宇宙船") }

      # Comment の content で判定したいので、content を固定（Factoryが content を持つ前提）
      let!(:comment) { create(:comment, user: create(:user), recipe: recipe, content: "これはスパムっぽいコメントです") }

      let!(:pending_recipe_report) do
        create(:report,
          reporter: reporter,
          reportable: recipe,
          status: :pending,
          reason: :spam,
          created_at: Time.zone.parse("2026-01-10 10:00:00")
        )
      end

      let!(:resolved_user_report) do
        create(:report,
          reporter: other_reporter,
          reportable: create(:user, name: "通報対象ユーザー"),
          status: :resolved,
          reason: :other,
          created_at: Time.zone.parse("2026-01-12 10:00:00")
        )
      end
      
  end
end