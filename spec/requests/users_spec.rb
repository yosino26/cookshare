require 'rails_helper'

RSpec.describe "Users", type: :request do
  let(:user) { create(:user) }

  # =========================
  # GET /users/:id (show)
  # =========================
  describe "GET /users/:id (show)" do
    context "when signed in" do
      before do
        sign_in user
      end

      it "returns http success" do
        get user_path(user)
        expect(response).to have_http_status(:success) # 200
      end
    end

    context "when not signed in" do
      it "redirects to sign in" do
        get user_path(user)
        expect(response).to have_http_status(:found)   # 302
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  # =========================
  # GET /users/:id/edit (edit)
  # =========================
  describe "GET /users/:id/edit (edit)" do
    context "when signed in" do
      before do
        sign_in user
      end

      it "returns http success" do
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

  # =========================
  # PATCH /users/:id (update)
  # =========================
  describe "PATCH /users/:id (update)" do
    let(:params) { { user: { name: "NewName" } } }

    context "when signed in" do
      before do
        sign_in user
      end

      it "updates and redirects to show" do
        patch user_path(user), params: params

        expect(response).to have_http_status(:found)   # 302
        expect(response).to redirect_to(user_path(user))

        follow_redirect!
        expect(response).to have_http_status(:success) # 200
        expect(response.body).to include("NewName")
      end
    end

    context "when not signed in" do
      it "redirects to sign in" do
        patch user_path(user), params: params
        expect(response).to have_http_status(:found)   # 302
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end