require 'rails_helper'

RSpec.describe "Users", type: :request do
  let(:user) { create(:user) }

  describe "GET /users/:id (show)" do
    context "ログイン済みの場合" do
      before do
        sign_in user
      end

      it "returns http success" do
        get user_path(user)
        expect(response).to have_http_status(:success) # 200
      end
    end
  end
end
