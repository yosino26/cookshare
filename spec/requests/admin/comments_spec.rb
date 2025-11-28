require 'rails_helper'

RSpec.describe "Admin::Comments", type: :request do
  let(:admin)    { create(:user, admin: true) }
  let!(:comment) { create(:comment) } # index用に1件用意

  before { sign_in admin }

  describe "GET /admin/comments (index)" do
    it "returns http success" do
      get admin_comments_path
      expect(response).to have_http_status(:success) # 200
    end
  end

  describe "DELETE /admin/comments/:id (destroy)" do
    it "redirects to index" do
      delete admin_comment_path(comment)             # DELETE が正しい
      expect(response).to have_http_status(:found)   # 302
      expect(response).to redirect_to(admin_comments_path)
    end
  end
end