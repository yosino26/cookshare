require 'rails_helper'

RSpec.describe "Recipes search and filter", type: :request do
  describe "GET /recipes with search keyword" do
    let!(:matching_title) do
      create(:recipe,
             title: "簡単オムライス",
             description: "ふわとろ卵で作るレシピ")
    end

    let!(:matching_description) do
      create(:recipe,
             title: "朝ごはんセット",
             description: "オムライス風の卵料理付きプレート")
    end

    let!(:non_matching) do
      create(:recipe,
             title: "スパイシーカレー",
             description: "スパイスたっぷりの本格カレー")
    end

    it "returns only recipes whose title or description includes the keyword" do
      get recipes_path, params: { search: "オムライス" }

      expect(response).to have_http_status(:ok)

      # ヒットしてほしいレシピ
      expect(response.body).to include(matching_title.title)
      expect(response.body).to include(matching_description.title)

      # ヒットしてほしくないレシピ
      expect(response.body).not_to include(non_matching.title)
    end
  end

  describe "GET /recipes with cooking_time filter" do
    let!(:quick_recipe) do
      create(:recipe,
             title: "10分パスタ",
             cooking_time: 10)
    end

    let!(:border_recipe) do
      create(:recipe,
             title: "30分煮込みハンバーグ",
             cooking_time: 30)
    end

    let!(:slow_recipe) do
      create(:recipe,
             title: "45分ビーフシチュー",
             cooking_time: 45)
    end

    it "returns only recipes whose cooking_time is less than or equal to the specified value" do
      get recipes_path, params: { cooking_time: 30 }

      expect(response).to have_http_status(:ok)

      # 30分以下は含まれる
      expect(response.body).to include(quick_recipe.title)
      expect(response.body).to include(border_recipe.title)

      # 31分以上は含まれない
      expect(response.body).not_to include(slow_recipe.title)
    end
  end
end