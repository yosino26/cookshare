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

end