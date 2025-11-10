require 'rails_helper'

RSpec.describe "Recipe happy path", type: :system do
  let(:user) { create(:user) }

  it "投稿→表示→コメント→お気に入り→評価" do
    login_as user, scope: :user   # ← ここを変更
    visit new_recipe_path
    fill_in "タイトル", with: "親子丼"
    fill_in "説明", with: "簡単レシピ"
    click_button "登録"
    expect(page).to have_content("親子丼")

    fill_in "コメント", with: "美味しそう！"
    click_button "送信"
    expect(page).to have_content("美味しそう！")

    click_button "お気に入り"
    expect(page).to have_content("お気に入り数 1").or have_content("お気に入り: 1")

    select "5", from: "rating_score"
    click_button "評価する"
    expect(page).to have_content("平均★5").or have_content("平均 5.0")
  end
end