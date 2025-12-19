require 'rails_helper'

RSpec.describe "Admin::Reports（管理画面の通報対応）", type: :request do
  let(:admin) { create(:user, admin: true) }
  let(:user)  { create(:user) }
  let!(:report) { create(:report, status: :pending) }

  describe "GET /admin/reports（通報一覧）" do
    context "管理者ユーザーの場合" do
      it "通報一覧ページを閲覧できる" do
        sign_in admin

        get admin_reports_path

        expect(response).to have_http_status(:ok)
        # 一覧にレポートが表示されていることをざっくり確認
        expect(response.body).to include(report.id.to_s)
      end
    end

    context "一般ユーザーの場合" do
      it "管理画面の通報一覧にアクセスできず、トップへリダイレクトされる" do
        sign_in user

        get admin_reports_path

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(root_path) # 実装に合わせて変更OK
      end
    end

    context "未ログインの場合" do
      it "通報一覧にアクセスできず、ログイン画面へリダイレクトされる" do
        get admin_reports_path

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "PATCH /admin/reports/:id/resolve（通報を対応済みにする）" do
    context "管理者ユーザーの場合" do
      it "通報のステータスを resolved に更新できる" do
        sign_in admin

        patch resolve_admin_report_path(report)

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(admin_report_path(report)) # 実装に合わせてOK

        report.reload
        expect(report.status).to eq("resolved")
      end
    end

    context "一般ユーザーの場合" do
      it "通報のステータスを変更できず、トップへリダイレクトされる" do
        sign_in user

        patch resolve_admin_report_path(report)

        report.reload
        # 一般ユーザーでは status が変わらない
        expect(report.status).to eq("pending")

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(root_path)
      end
    end

    context "未ログインの場合" do
      it "通報のステータスを変更できず、ログイン画面へリダイレクトされる" do
        patch resolve_admin_report_path(report)

        report.reload
        expect(report.status).to eq("pending")

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "GET /admin/reports/:id（通報詳細）" do
    context "管理者ユーザーの場合" do
      it "通報の詳細ページを閲覧できる" do
        sign_in admin

        get admin_report_path(report)

        expect(response).to have_http_status(:ok)
        # 通報IDやステータスなど、通報詳細が表示されていることをざっくり確認
        expect(response.body).to include(report.id.to_s)
        expect(response.body).to include("レポート詳細") # ページヘッダー
        expect(response.body).to include("未対応")       # pending の表示ラベル
      end
    end

    context "一般ユーザーの場合" do
      it "通報詳細にアクセスできず、トップへリダイレクトされる" do
        sign_in user

        get admin_report_path(report)

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(root_path)
      end
    end

    context "未ログインの場合" do
      it "通報詳細にアクセスできず、ログイン画面へリダイレクトされる" do
        get admin_report_path(report)

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end