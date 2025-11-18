require 'rails_helper'

RSpec.describe "Users", type: :request do
  let(:user) { create(:user) }

  describe "GET /users/:id (show)" do
    it "returns http success" do
      get user_path(user)
      expect(response).to have_http_status(:success) # 200
    end
  end

  describe "GET /users/:id/edit (edit)" do
    context "when signed in" do
      it "returns http success" do
        sign_in user
        get edit_user_path(user)
        expect(response).to have_http_status(:success) # 200
      end
    end

    context "when not signed in" do
      it "redirects to sign in" do
        get edit_user_path(user)
        expect(response).to have_http_status(:found)   # 302
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "PATCH /users/:id (update)" do
    context "when signed in" do
      it "updates and redirects to show" do
        sign_in user
        patch user_path(user), params: { user: { name: "NewName" } }
        expect(response).to have_http_status(:found)   # 302
        expect(response).to redirect_to(user_path(user))

        follow_redirect!
        expect(response).to have_http_status(:success) # 200
        expect(response.body).to include("NewName")
      end
    end

    context "when not signed in" do
      it "redirects to sign in" do
        patch user_path(user), params: { user: { name: "NewName" } }
        expect(response).to have_http_status(:found)   # 302
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end