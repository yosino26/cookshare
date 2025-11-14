require 'rails_helper'

RSpec.describe "API Recipes index", type: :request do
  let(:headers) { { "ACCEPT" => "application/json" } }

  it "recent順（created_at desc, id descの安定二段）" do
    travel_to(1.day.ago) { create(:recipe, :published, title: "old") }
    a = create(:recipe, :published, title: "new-a")
    b = create(:recipe, :published, title: "new-b")

    get "/api/recipes", headers: headers
    ids = JSON.parse(response.body).map { |h| h["id"] }
    expect(ids).to eq([b.id, a.id, Recipe.find_by(title: "old").id])
  end

  it "ページ跨ぎで重複なし（per=12前提）" do
    create_list(:recipe, 25, :published)

    get "/api/recipes", params: { page: 1 }, headers: headers
    page1 = JSON.parse(response.body).map { |h| h["id"] }

    get "/api/recipes", params: { page: 2 }, headers: headers
    page2 = JSON.parse(response.body).map { |h| h["id"] }

    expect(page1.size).to eq(12)
    expect(page2.size).to eq(12)
    expect(page1 & page2).to be_empty
  end

  it "カテゴリ絞り込みで該当のみ" do
    cat1 = create(:category, name: "丼")
    cat2 = create(:category, name: "麺")
    r1 = create(:recipe, :published); create(:recipe_category, recipe: r1, category: cat1)
    r2 = create(:recipe, :published); create(:recipe_category, recipe: r2, category: cat2)

    get "/api/recipes", params: { category_id: cat1.id }, headers: headers
    ids = JSON.parse(response.body).map { |h| h["id"] }
    expect(ids).to include(r1.id)
    expect(ids).not_to include(r2.id)
  end
end