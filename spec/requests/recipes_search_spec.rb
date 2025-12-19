require 'rails_helper'

RSpec.describe "レシピ検索と絞り込み", type: :request do
  describe "検索キーワード付きの GET /recipes" do
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

    it "タイトルまたは説明文にキーワードを含むレシピだけを返す" do
      get recipes_path, params: { search: "オムライス" }

      expect(response).to have_http_status(:ok)

      # ヒットしてほしいレシピ
      expect(response.body).to include(matching_title.title)
      expect(response.body).to include(matching_description.title)

      # ヒットしてほしくないレシピ
      expect(response.body).not_to include(non_matching.title)
    end
  end

  describe "調理時間フィルター付きの GET /recipes" do
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

    it "指定した調理時間以下のレシピだけを返す" do
      get recipes_path, params: { cooking_time: 30 }

      expect(response).to have_http_status(:ok)

      # 30分以下は含まれる
      expect(response.body).to include(quick_recipe.title)
      expect(response.body).to include(border_recipe.title)

      # 31分以上は含まれない
      expect(response.body).not_to include(slow_recipe.title)
    end
  end

  describe "検索キーワードと調理時間フィルターを併用した GET /recipes" do
    let!(:match_both) do
      create(:recipe,
             title: "15分オムライス",
             description: "オムライスの時短レシピ",
             cooking_time: 15)
    end

    let!(:match_keyword_only) do
      create(:recipe,
             title: "じっくり煮込むオムライス",
             description: "オムライスだけど時間がかかる",
             cooking_time: 45)
    end

    let!(:match_time_only) do
      create(:recipe,
             title: "15分サンドイッチ",
             description: "パンと野菜のシンプルな軽食",  # ← ここを変更
             cooking_time: 15)
    end

    it "キーワード条件と調理時間条件の両方を満たすレシピだけを返す" do
      get recipes_path, params: { search: "オムライス", cooking_time: 30 }

      expect(response).to have_http_status(:ok)

      # キーワード＆時間の両方を満たすレシピだけ含まれる
      expect(response.body).to include(match_both.title)

      # キーワードだけ or 時間だけ一致するレシピは含まれない
      expect(response.body).not_to include(match_keyword_only.title)
      expect(response.body).not_to include(match_time_only.title)
    end
  end
end