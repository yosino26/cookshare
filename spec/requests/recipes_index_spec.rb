require 'rails_helper'

RSpec.describe "Recipes index", type: :request do
  it "recent順（created_at desc, id descの安定順）" do
    travel_to(1.day.ago) { create(:recipe, title: "old") }
    a = create(:recipe, title: "new-a")
    b = create(:recipe, title: "new-b") # ほぼ同時刻タイの可能性

    get recipes_path
    ids = assigns(:recipes).map(&:id)
    # 同時刻タイでもid降順で安定している想定
    expect(ids).to eq([b.id, a.id, Recipe.find_by(title: "old").id])
  end

  it "ページを跨いでも重複しない（例: 1ページ=20件想定）" do
    create_list(:recipe, 25)
    get recipes_path(page: 1)
    page1 = assigns(:recipes).map(&:id)
    get recipes_path(page: 2)
    page2 = assigns(:recipes).map(&:id)
    expect(page1 & page2).to be_empty
  end

  it "カテゴリ絞り込みで該当のみが返る" do
    cat1 = create(:category, name: "丼")
    cat2 = create(:category, name: "麺")
    r1 = create(:recipe); create(:recipe_category, recipe: r1, category: cat1)
    r2 = create(:recipe); create(:recipe_category, recipe: r2, category: cat2)

    get recipes_path(category_id: cat1.id)
    ids = assigns(:recipes).map(&:id)
    expect(ids).to include(r1.id)
    expect(ids).not_to include(r2.id)
  end
end