require 'rails_helper'

RSpec.describe "Users", type: :request do
  let(:user) { create(:user) }

  describe "GET /users/:id (show)" do
    context "未ログインの場合" do
      it "ログイン画面にリダイレクトされる" do
        get user_path(user)

        # ここで実際の挙動をテストで固定する
        expect(response).to have_http_status(:found) # 302
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end