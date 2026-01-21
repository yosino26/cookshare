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
  end
end