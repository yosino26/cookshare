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
      let!(:reporter)       { create(:user, email: "reporter@example.com") }
      let!(:other_reporter) { create(:user, email: "other@example.com") }

      let!(:recipe)  { create(:recipe, user: create(:user), title: "寿司タワー") }
      let!(:comment) { create(:comment, user: create(:user), recipe: recipe, content: "これはスパムっぽいコメントです") }

      # created_at がFactory/コールバック等で上書きされる可能性があるので、DB直で固定する
      def force_created_at!(record, t)
        record.update_columns(created_at: t, updated_at: t)
      end

      let!(:pending_recipe_report) do
        r = create(:report,
          reporter: reporter,
          reportable: recipe,
          status: :pending,
          reason: :spam
        )
        force_created_at!(r, Time.zone.parse("2026-01-10 10:00:00"))
        r
      end

      let!(:resolved_user_report) do
        r = create(:report,
          reporter: other_reporter,
          reportable: create(:user, name: "通報対象ユーザー"),
          status: :resolved,
          reason: :other
        )
        force_created_at!(r, Time.zone.parse("2026-01-12 10:00:00"))
        r
      end

      let!(:investigating_comment_report) do
        # コメント本文（content）が view 側や model 側の仕様で空になると不安定なので、
        # 表示が確実な reason をユニークにして検証材料にする
        r = create(:report,
          reporter: reporter,
          reportable: comment,
          status: :investigating,
          reason: :copyright
        )
        force_created_at!(r, Time.zone.parse("2026-01-15 10:00:00"))
        r
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
        expect(body).not_to include("copyright") # comment report を除外できていること
      end

      it "reportable_type 指定で絞り込める（Recipe）" do
        get admin_reports_path, params: { reportable_type: "Recipe" }
        expect(response).to have_http_status(:ok)

        body = response.body
        expect(body).to include("寿司タワー")
        expect(body).not_to include("通報対象ユーザー")
        expect(body).not_to include("copyright")
      end

      it "reportable_type 指定で絞り込める（User）" do
        get admin_reports_path, params: { reportable_type: "User" }
        expect(response).to have_http_status(:ok)

        body = response.body
        expect(body).to include("通報対象ユーザー")
        expect(body).not_to include("寿司タワー")
        expect(body).not_to include("copyright")
      end

      it "期間（date_from / date_to）で絞り込める" do
        get admin_reports_path, params: { date_from: "2026-01-11", date_to: "2026-01-13" }
        expect(response).to have_http_status(:ok)

        body = response.body
        expect(body).to include("other@example.com")
        expect(body).to include("通報対象ユーザー")

        expect(body).not_to include("寿司タワー")
        expect(body).not_to include("copyright")
      end

      it "フィルターなしは全件が表示される" do
        # まずデータが揃ってることを保証（ここで落ちたらセットアップの問題）
        expect(Report.count).to eq 3

        get admin_reports_path
        expect(response).to have_http_status(:ok)

        body = response.body
        expect(body).to include("寿司タワー")
        expect(body).to include("通報対象ユーザー")
        expect(body).to include("copyright")
      end
    end

    context "並び順（デフォルト: created_at desc）" do
      let!(:reporter)   { create(:user, email: "order@example.com") }
      let!(:recipe_old) { create(:recipe, user: create(:user), title: "古いレシピ") }
      let!(:recipe_new) { create(:recipe, user: create(:user), title: "新しいレシピ") }

      def force_created_at!(record, t)
        record.update_columns(created_at: t, updated_at: t)
      end

      let!(:old_report) do
        r = create(:report,
          reporter: reporter,
          reportable: recipe_old,
          status: :pending,
          reason: :spam
        )
        force_created_at!(r, Time.zone.parse("2026-01-10 10:00:00"))
        r
      end

      let!(:new_report) do
        r = create(:report,
          reporter: reporter,
          reportable: recipe_new,
          status: :pending,
          reason: :spam
        )
        force_created_at!(r, Time.zone.parse("2026-01-20 10:00:00"))
        r
      end

      before { sign_in admin }

      it "新しい方が先に出現する（同時刻のid比較はしない）" do
        get admin_reports_path
        expect(response).to have_http_status(:ok)

        body = response.body
        pos_new = body.index("新しいレシピ")
        pos_old = body.index("古いレシピ")

        expect(pos_new).not_to be_nil
        expect(pos_old).not_to be_nil
        expect(pos_new).to be < pos_old
      end
    end
  end
end
