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

end