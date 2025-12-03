require 'rails_helper'

RSpec.describe "Recipes", type: :request do
  describe "GET /recipes" do
    it "一覧ページが表示されること" do
      get recipes_path
      expect(response).to have_http_status(:ok) # 200
    end
  end
end
