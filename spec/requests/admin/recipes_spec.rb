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

      # ==== ここでリダイレクト先と中身を確認 ====
      puts "=== DEBUG Admin::Recipes#index ==="
      puts "status:   #{response.status}"
      puts "location: #{response.location.inspect}"
      puts "body head: #{response.body[0..200].gsub(/\s+/, ' ')}"
      puts "==================================="
      # =====================================

      expect(response).to have_http_status(:success) # 200
    end
  end
end