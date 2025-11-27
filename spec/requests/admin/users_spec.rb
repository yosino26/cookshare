# spec/requests/admin/recipes_spec.rb
require 'rails_helper'

RSpec.describe "Admin::Recipes", type: :request do
  let(:admin)  { create(:user, admin: true) }
  let!(:recipe) { create(:recipe) } # 一覧用に1件

  before do
    sign_in admin
  end

  describe "GET /admin/recipes (index)" do
    it "returns http success" do
      get admin_recipes_path
      expect(response).to have_http_status(:success) # 200
    end
  end

  # 必要なら今後 show/edit/update/hide もここに追加していく
end