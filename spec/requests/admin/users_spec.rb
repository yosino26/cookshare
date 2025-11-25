require 'rails_helper'

RSpec.describe "Admin::Users", type: :request do
  let(:admin) { create(:user, admin: true) } # 管理者ユーザー
  let!(:user) { create(:user) }              # 対象ユーザー

  before do
    sign_in admin
  end

  # =========================
  # GET /admin/users (index)
  # =========================
  describe "GET /admin/users (index)" do
    it "returns http success" do
      get admin_users_path
      expect(response).to have_http_status(:success) # 200
    end
  end

  # =========================
  # GET /admin/users/:id (show)
  # =========================
  describe "GET /admin/users/:id (show)" do
    it "returns http success" do
      get admin_user_path(user)
      expect(response).to have_http_status(:success) # 200
    end
  end

  # =========================
  # GET /admin/users/:id/edit (edit)
  # =========================
  describe "GET /admin/users/:id/edit (edit)" do
    it "returns http success" do
      get edit_admin_user_path(user)
      expect(response).to have_http_status(:success) # 200
    end
  end

  # =========================
  # PATCH /admin/users/:id (update)
  # =========================
  describe "PATCH /admin/users/:id (update)" do
    it "updates and redirects" do
      patch admin_user_path(user), params: { user: { name: "AdminUpdated" } }

      expect(response).to have_http_status(:found) # 302
      expect(response).to redirect_to(admin_user_path(user))
    end
  end

  # =========================
  # PATCH /admin/users/:id/toggle_admin
  # =========================
  describe "PATCH /admin/users/:id/toggle_admin" do
    it "toggles admin flag and redirects" do
      patch toggle_admin_admin_user_path(user)

      expect(response).to have_http_status(:found) # 302
      expect(response).to redirect_to(admin_users_path)
    end
  end
end